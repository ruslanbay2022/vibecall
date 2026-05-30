import 'dart:async';

import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/data/call_token.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';

part 'call_controller.g.dart';

@Riverpod(keepAlive: true)
class CallController extends _$CallController {
  Room? _room;
  DateTime? _connectedAt;
  String? _currentInvitationId;
  bool _hasVideo = true;
  StreamSubscription<CallInvitation>? _outgoingSub;
  CancelListenFunc? _onParticipantConnected;
  CancelListenFunc? _onParticipantDisconnected;
  CancelListenFunc? _onRoomDisconnected;
  bool _hangupInProgress = false;

  /// Override in tests to mock LiveKit connection.
  Future<void> Function(CallToken token, {required bool video})?
      connectRoomOverride;

  @override
  CallState build() {
    ref.onDispose(_dispose);
    return const CallStateIdle();
  }

  /// Called by incoming-call listener (Step 3.7) when a ringing invitation arrives.
  void notifyIncoming(CallInvitation invitation) {
    if (state is! CallStateIdle) return;
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
    if (state is! CallStateIdle) return;
    _hasVideo = video;
    state = const CallStateConnecting();

    try {
      final repo = ref.read(callRepositoryProvider);
      final token = await repo.startCall(receiverId, hasVideo: video);
      _currentInvitationId = await _resolveInvitationId(token.roomName);
      _subscribeOutgoingUpdates(_currentInvitationId!);
      state = CallStateOutgoing(
        roomName: token.roomName,
        receiverId: receiverId,
      );
      await _connectRoom(token, video: video);
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
    state = const CallStateConnecting();

    try {
      final repo = ref.read(callRepositoryProvider);
      final token = await repo.acceptCall(inv.id);
      _currentInvitationId = inv.id;
      await _connectRoom(token, video: inv.hasVideo);
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
      _cleanup();
      state = CallStateEnded(outcome: CallOutcome.accepted, durationSec: durationSec);
    } finally {
      _hangupInProgress = false;
    }
  }

  Future<void> toggleMute() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    await participant.setMicrophoneEnabled(!participant.isMicrophoneEnabled());
  }

  Future<void> toggleCamera() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    await participant.setCameraEnabled(!participant.isCameraEnabled());
  }

  Future<void> switchCamera() async {
    final track = _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track == null) return;
    await track.switchCamera('');
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

  Future<void> _connectRoom(CallToken token, {required bool video}) async {
    if (connectRoomOverride != null) {
      await connectRoomOverride!(token, video: video);
      return;
    }

    final room = Room();
    _room = room;

    _onParticipantConnected =
        room.events.on<ParticipantConnectedEvent>((event) {
      _connectedAt = DateTime.now();
      state = CallStateActive(
        room: room,
        peer: event.participant,
        hasVideo: _hasVideo,
      );
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

    await room.connect(token.wsUrl, token.token);
    await room.localParticipant?.setMicrophoneEnabled(true);
    if (video) {
      await room.localParticipant?.setCameraEnabled(true);
    }
  }

  void _cleanup() {
    _outgoingSub?.cancel();
    _outgoingSub = null;
    _onParticipantConnected?.call();
    _onParticipantDisconnected?.call();
    _onRoomDisconnected?.call();
    _onParticipantConnected = null;
    _onParticipantDisconnected = null;
    _onRoomDisconnected = null;
    _room?.disconnect();
    _room = null;
    _currentInvitationId = null;
    _connectedAt = null;
  }

  void _dispose() {
    _cleanup();
  }
}
