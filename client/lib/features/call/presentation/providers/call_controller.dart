import 'dart:async';

import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/data/call_token.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' show BuildContext;
import 'package:vibecall/features/call/data/call_media_permissions.dart';
import 'package:vibecall/features/call/presentation/call_screen_share.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/widgets/call_media_utils.dart';
import 'package:vibecall/features/chat/presentation/providers/in_call_open_chat.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'call_controller.g.dart';

@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  Room? _room;
  DateTime? _connectedAt;
  String? _currentInvitationId;
  String? _peerUserId;
  bool _hasVideo = true;
  StreamSubscription<CallInvitation>? _outgoingSub;
  CancelListenFunc? _onParticipantConnected;
  CancelListenFunc? _onParticipantDisconnected;
  CancelListenFunc? _onRoomDisconnected;
  CancelListenFunc? _onRoomMediaChanged;
  bool _hangupInProgress = false;
  bool _screenShareBusy = false;
  bool _cameraBusy = false;

  /// Override in tests to mock LiveKit connection.
  Future<void> Function(CallToken token, {required bool video})?
      connectRoomOverride;

  @override
  CallState build() {
    ref.onDispose(_dispose);
    return const CallStateIdle();
  }

  /// True when not in the middle of an active call flow (connecting/outgoing/active).
  bool get _canStartNewCall {
    return switch (state) {
      CallStateConnecting() || CallStateOutgoing() || CallStateActive() => false,
      _ => true,
    };
  }

  /// Called by incoming-call listener (Step 3.7) when a ringing invitation arrives.
  void notifyIncoming(CallInvitation invitation) {
    if (!_canStartNewCall) return;
    state = CallStateIncoming(invitation: invitation);
  }

  /// Reset from incoming state to idle (used by overlay on reject/dismiss).
  void clearIncoming() {
    if (state is CallStateIncoming) {
      _cleanup();
      state = const CallStateIdle();
    }
  }

  int _computeDuration() {
    final connectedAt = _connectedAt;
    return connectedAt != null
        ? DateTime.now().difference(connectedAt).inSeconds
        : 0;
  }

  void _setEnded(CallOutcome outcome) {
    final durationSec = _computeDuration();
    _cleanup();
    state = CallStateEnded(outcome: outcome, durationSec: durationSec);
  }

  Future<void> startCall({
    required String receiverId,
    required bool video,
  }) async {
    if (!_canStartNewCall) return;
    _hasVideo = video;
    _peerUserId = receiverId;
    state = const CallStateConnecting();

    if (!await CallMediaPermissions.ensureForCall(video: video)) {
      state = const CallStateError(
        message: callMediaPermissionDeniedMessageId,
      );
      return;
    }

    try {
      final repo = ref.read(callRepositoryProvider);
      final token = await repo.startCall(receiverId, hasVideo: video);
      _currentInvitationId = await _resolveInvitationId(token.roomName);
      _subscribeOutgoingUpdates(_currentInvitationId!);
      state = CallStateOutgoing(
        roomName: token.roomName,
        receiverId: receiverId,
      );
      await _connectRoom(
        token,
        video: video,
        enableLocalCamera: video,
      );
    } on CallBusyException {
      _setEnded(CallOutcome.busy);
    } catch (e) {
      _cleanup();
      state = CallStateError(message: e.toString());
    }
  }

  Future<void> accept(CallInvitation inv) async {
    if (state is! CallStateIncoming) return;
    _hasVideo = inv.hasVideo;
    _peerUserId = inv.callerId;
    state = const CallStateConnecting();

    if (!await CallMediaPermissions.ensureMicrophone()) {
      state = const CallStateError(
        message: callMediaPermissionDeniedMessageId,
      );
      return;
    }

    try {
      final repo = ref.read(callRepositoryProvider);
      final token = await repo.acceptCall(inv.id);
      _currentInvitationId = inv.id;
      await _connectRoom(
        token,
        video: inv.hasVideo,
        enableLocalCamera: false,
      );
    } catch (e) {
      _cleanup();
      state = CallStateError(message: e.toString());
    }
  }

  Future<void> reject(CallInvitation inv) async {
    try {
      final repo = ref.read(callRepositoryProvider);
      await repo.rejectCall(inv.id);
    } catch (_) {}
    _setEnded(CallOutcome.rejected);
  }

  Future<void> cancel() async {
    if (_currentInvitationId != null) {
      try {
        final repo = ref.read(callRepositoryProvider);
        await repo.cancelCall(_currentInvitationId!);
      } catch (_) {}
    }
    _setEnded(CallOutcome.cancelled);
  }

  Future<void> hangup() async {
    if (_hangupInProgress) return;
    _hangupInProgress = true;
    try {
      final durationSec = _computeDuration();
      if (_currentInvitationId != null) {
        try {
          final repo = ref.read(callRepositoryProvider);
          await repo.endCall(_currentInvitationId!, durationSec);
        } catch (_) {}
      }
      await _stopLocalScreenShareIfNeeded();
      _cleanup();
      state = CallStateEnded(outcome: CallOutcome.accepted, durationSec: durationSec);
    } finally {
      _hangupInProgress = false;
    }
  }

  Future<void> _stopLocalScreenShareIfNeeded() async {
    try {
      final participant = _room?.localParticipant;
      if (participant != null) {
        await _unpublishLocalScreenShare(participant);
      }
    } catch (_) {}
  }

  Future<void> _unpublishLocalScreenShare(LocalParticipant participant) async {
    await CallScreenShare.unpublishScreenTracks(participant);
  }

  Future<void> toggleMute() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    try {
      final enabling = !participant.isMicrophoneEnabled();
      if (enabling && !await CallMediaPermissions.ensureMicrophone()) {
        return;
      }
      await participant.setMicrophoneEnabled(enabling);
      _refreshActiveState();
    } catch (_) {}
  }

  /// Returns false when enabling the camera failed (e.g. device in use).
  ///
  /// Uses [LocalParticipant.setCameraEnabled] symmetrically (mute/unmute) so the
  /// camera track keeps a stable sid across toggles. Unpublishing + republishing
  /// instead churned the sid, triggering renegotiation, renderer rebuilds and
  /// races (web Uncaught Error, Android white frame).
  Future<bool> toggleCamera() async {
    if (_cameraBusy) return false;
    final participant = _room?.localParticipant;
    if (participant == null) return false;

    final pub = participant.getTrackPublicationBySource(TrackSource.camera);
    final cameraOn = pub != null && !pub.muted;

    _cameraBusy = true;
    try {
      if (!cameraOn && !await CallMediaPermissions.ensureCamera()) {
        return false;
      }
      await participant.setCameraEnabled(!cameraOn);
      _refreshActiveState();
      return true;
    } catch (_) {
      _refreshActiveState();
      return false;
    } finally {
      _cameraBusy = false;
    }
  }

  Future<void> switchCamera() async {
    final track = _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track == null) return;
    await track.switchCamera('');
  }

  /// Returns false when enabling screen share failed (picker denied, service error).
  /// Pass [context] on desktop for [ScreenSelectDialog] (all monitors/windows).
  Future<bool> toggleScreenShare({BuildContext? context}) async {
    if (_screenShareBusy) return false;
    final participant = _room?.localParticipant;
    if (participant == null) return false;

    _screenShareBusy = true;
    final isStopping = isParticipantScreenSharing(participant);
    if (kDebugMode) {
      debugPrint('[ScreenShare] toggle start, hasVideo=$_hasVideo, stopping=$isStopping');
    }
    try {
      if (isStopping) {
        await _unpublishLocalScreenShare(participant);
        if (kDebugMode) {
          debugPrint('[ScreenShare] stop complete');
        }
      } else {
        if (lkPlatformIsDesktop() && context != null && !context.mounted) {
          _refreshActiveState();
          return false;
        }
        final pub = await CallScreenShare.start(
          participant,
          context: context,
          onEnded: _onScreenShareEndedByBrowser,
        );
        if (pub == null || pub.track == null) {
          if (kDebugMode) {
            debugPrint('[ScreenShare] start failed: publication or track is null');
          }
          _refreshActiveState();
          return false;
        }
        if (kDebugMode) {
          debugPrint('[ScreenShare] start success, publication sid=${pub.sid}, track sid=${pub.track?.sid}');
        }
      }
      _refreshActiveState();
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[ScreenShare] toggle failed: $e\n$st');
      }
      _refreshActiveState();
      return false;
    } finally {
      _screenShareBusy = false;
    }
  }

  Future<void> _onScreenShareEndedByBrowser() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    try {
      await _unpublishLocalScreenShare(participant);
    } catch (_) {}
    _refreshActiveState();
  }

  void resetToIdle() {
    _cleanup();
    state = const CallStateIdle();
  }

  Future<String> _resolveInvitationId(String roomName) async {
    final client = Supabase.instance.client;
    final result = await client
        .from('call_invitations')
        .select('id')
        .eq('room_name', roomName)
        .eq('caller_id', client.auth.currentUser!.id)
        .maybeSingle();
    if (result == null) throw 'Invitation not found for room: $roomName';
    return result['id'] as String;
  }

  void _subscribeOutgoingUpdates(String invitationId) {
    _outgoingSub?.cancel();
    final repo = ref.read(callRepositoryProvider);
    _outgoingSub = repo.outgoingCallUpdates(invitationId).listen((inv) {
      switch (inv.state) {
        case 'rejected':
          _setEnded(CallOutcome.rejected);
        case 'missed':
          _setEnded(CallOutcome.missed);
        case 'cancelled':
          _setEnded(CallOutcome.cancelled);
        case 'timeout':
          _setEnded(CallOutcome.timeout);
      }
    });
  }

  Future<void> _connectRoom(
    CallToken token, {
    required bool video,
    required bool enableLocalCamera,
  }) async {
    if (connectRoomOverride != null) {
      await connectRoomOverride!(token, video: video);
      return;
    }

    final room = Room(
      roomOptions: const RoomOptions(
        fastPublish: false,
        defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
          captureScreenAudio: false,
          preferCurrentTab: false,
        ),
      ),
    );
    _room = room;

    _onParticipantConnected =
        room.events.on<ParticipantConnectedEvent>((event) {
      _promoteToActive(room, peer: event.participant);
    });

    _onParticipantDisconnected =
        room.events.on<ParticipantDisconnectedEvent>((event) {
      hangup();
    });

    _onRoomDisconnected = room.events.on<RoomDisconnectedEvent>((event) {
      final durationSec = _computeDuration();
      _cleanup();
      state = CallStateEnded(outcome: CallOutcome.accepted, durationSec: durationSec);
    });

    _subscribeRoomMedia(room);

    await room.connect(
      token.wsUrl,
      token.token,
      connectOptions: const ConnectOptions(
        timeouts: Timeouts(
          connection: Duration(seconds: 15),
          debounce: Duration(milliseconds: 20),
          publish: Duration(seconds: 20),
          subscribe: Duration(seconds: 10),
          peerConnection: Duration(seconds: 15),
          iceRestart: Duration(seconds: 10),
        ),
      ),
    );
    await _enableLocalTracks(
      room.localParticipant,
      enableLocalCamera: enableLocalCamera,
    );

    // Callee accept: caller may already be in the room — ParticipantConnected
    // does not re-fire for existing remotes; check after connect.
    _promoteToActive(room);
  }

  /// Enables mic/camera without failing the call when hardware is busy or denied.
  Future<void> _enableLocalTracks(
    LocalParticipant? participant, {
    required bool enableLocalCamera,
  }) async {
    if (participant == null) return;
    try {
      await participant.setMicrophoneEnabled(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallController] setMicrophoneEnabled failed: $e');
      }
    }
    if (!enableLocalCamera) return;
    try {
      await participant.setCameraEnabled(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallController] setCameraEnabled failed: $e');
      }
    }
  }

  void _subscribeRoomMedia(Room room) {
    _onRoomMediaChanged?.call();
    final cancels = <CancelListenFunc>[
      room.events.on<LocalTrackPublishedEvent>((event) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] LocalTrackPublished: source=${event.publication.source}, sid=${event.publication.sid}');
        }
        _refreshActiveState();
      }),
      room.events.on<LocalTrackUnpublishedEvent>((event) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] LocalTrackUnpublished: source=${event.publication.source}, sid=${event.publication.sid}');
        }
        _refreshActiveState();
      }),
      room.events.on<TrackPublishedEvent>((event) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] TrackPublished (remote): participant=${event.participant.identity}, source=${event.publication.source}, sid=${event.publication.sid}');
        }
        _refreshActiveState();
      }),
      room.events.on<TrackUnpublishedEvent>((event) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] TrackUnpublished (remote): participant=${event.participant.identity}, source=${event.publication.source}, sid=${event.publication.sid}');
        }
        _refreshActiveState();
      }),
      room.events.on<TrackSubscribedEvent>((event) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] TrackSubscribed: source=${event.publication.source}, sid=${event.track.sid}');
        }
        _refreshActiveState();
      }),
      room.events.on<TrackUnsubscribedEvent>((event) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] TrackUnsubscribed: source=${event.publication.source}, sid=${event.track.sid}');
        }
        _refreshActiveState();
      }),
      room.events.on<TrackMutedEvent>((_) => _refreshActiveState()),
      room.events.on<TrackUnmutedEvent>((_) => _refreshActiveState()),
    ];
    _onRoomMediaChanged = () async {
      for (final cancel in cancels) {
        await cancel();
      }
    };
  }

  /// Re-emits [CallStateActive] so HUD/video views rebuild after media changes.
  void _refreshActiveState() {
    final current = state;
    if (current is! CallStateActive || _room == null) return;
    state = CallStateActive(
      room: current.room,
      peer: current.peer,
      peerUserId: current.peerUserId,
      hasVideo: current.hasVideo,
      mediaTick: current.mediaTick + 1,
    );
  }

  void _promoteToActive(Room room, {RemoteParticipant? peer}) {
    if (state is CallStateActive) return;
    if (state is! CallStateConnecting && state is! CallStateOutgoing) {
      return;
    }

    final remote = peer ?? room.remoteParticipants.values.firstOrNull;
    if (remote == null) return;

    final peerUserId = _peerUserId;
    if (peerUserId == null) return;

    _connectedAt = DateTime.now();
    _setCallWakelock(enabled: true);
    state = CallStateActive(
      room: room,
      peer: remote,
      peerUserId: peerUserId,
      hasVideo: _hasVideo,
    );
  }

  void _cleanup() {
    _setCallWakelock(enabled: false);
    _outgoingSub?.cancel();
    _outgoingSub = null;
    _onParticipantConnected?.call();
    _onParticipantDisconnected?.call();
    _onRoomDisconnected?.call();
    _onRoomMediaChanged?.call();
    _onParticipantConnected = null;
    _onParticipantDisconnected = null;
    _onRoomDisconnected = null;
    _onRoomMediaChanged = null;
    _room?.disconnect();
    _room = null;
    _currentInvitationId = null;
    _connectedAt = null;
    _peerUserId = null;
    if (ref.mounted) {
      ref.read(inCallOpenChatProvider.notifier).set(null);
    }
  }

  void _dispose() {
    _cleanup();
  }

  void _setCallWakelock({required bool enabled}) {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    unawaited(() async {
      try {
        if (enabled) {
          await WakelockPlus.enable();
        } else {
          await WakelockPlus.disable();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CallController] wakelock ${enabled ? 'enable' : 'disable'} failed: $e');
        }
      }
    }());
  }
}
