import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:vibecall/features/call/presentation/widgets/call_media_utils.dart';

typedef ScreenShareEndedCallback = Future<void> Function();

/// Screen-share publish options — simulcast off avoids Web publish timeouts
/// when camera + screen are both active.
const _screenSharePublishOptions = VideoPublishOptions(
  simulcast: false,
  degradationPreference: DegradationPreference.maintainResolution,
  name: VideoPublishOptions.defaultScreenShareName,
);

const _webCaptureOptions = ScreenShareCaptureOptions(
  captureScreenAudio: false,
  preferCurrentTab: false,
);

/// Settle delay after unpublishing camera before publishing screen share.
/// Avoids LiveKit publish timeout when camera + screen negotiate in parallel.
const _webCameraUnpublishSettle = Duration(milliseconds: 400);

/// Starts local screen share with platform-appropriate capture UI.
class CallScreenShare {
  CallScreenShare._();

  static bool _pausedCameraForWebShare = false;

  /// Removes published screen-share tracks (video + tab audio if any).
  /// Restores camera when it was paused for web screen share.
  static Future<void> unpublishScreenTracks(LocalParticipant participant) async {
    if (kDebugMode) {
      debugPrint('[ScreenShare] unpublishScreenTracks called');
    }
    final screenPub =
        participant.getTrackPublicationBySource(TrackSource.screenShareVideo);
    if (screenPub != null) {
      if (kDebugMode) {
        debugPrint('[ScreenShare] removing screenShareVideo track, sid=${screenPub.sid}');
      }
      await participant.removePublishedTrack(screenPub.sid);
    }
    final audioPub =
        participant.getTrackPublicationBySource(TrackSource.screenShareAudio);
    if (audioPub != null) {
      if (kDebugMode) {
        debugPrint('[ScreenShare] removing screenShareAudio track, sid=${audioPub.sid}');
      }
      await participant.removePublishedTrack(audioPub.sid);
    }
    await _restoreCameraIfPaused(participant);
    if (kDebugMode) {
      debugPrint('[ScreenShare] unpublishScreenTracks complete');
    }
  }

  static Future<void> _restoreCameraIfPaused(LocalParticipant participant) async {
    if (!_pausedCameraForWebShare) return;
    _pausedCameraForWebShare = false;
    await _enableCamera(participant);
  }

  static Future<void> _enableCamera(LocalParticipant participant) async {
    try {
      await participant.setCameraEnabled(true);
    } catch (_) {}
  }

  /// Web: unpublish camera so only one video track negotiates at a time.
  static Future<bool> _pauseCameraForWebShare(
    LocalParticipant participant,
  ) async {
    if (!isParticipantCameraOn(participant)) return false;
    final cameraPub =
        participant.getTrackPublicationBySource(TrackSource.camera);
    if (cameraPub == null) return false;
    await participant.removePublishedTrack(cameraPub.sid);
    await Future<void>.delayed(_webCameraUnpublishSettle);
    return true;
  }

  /// Web: relaxed `getDisplayMedia({video: true})` (fixes Edge / strict constraints).
  /// Windows/macOS/Linux desktop: [ScreenSelectDialog] with all screens/windows.
  /// Android: LiveKit [LocalParticipant.setScreenShareEnabled].
  ///
  /// Capture runs as the first await (user-gesture). No unpublish before capture.
  static Future<LocalTrackPublication<LocalVideoTrack>?> start(
    LocalParticipant participant, {
    BuildContext? context,
    ScreenShareEndedCallback? onEnded,
  }) async {
    if (kDebugMode) {
      debugPrint('[ScreenShare] start called, platform=${lkPlatformIsDesktop() ? "desktop" : kIsWeb ? "web" : "mobile"}');
    }
    if (lkPlatformIsDesktop() && context != null) {
      return _startDesktop(participant, context, onEnded);
    }
    if (kIsWeb) {
      return _startWeb(participant, onEnded);
    }
    await unpublishScreenTracks(participant);
    if (kDebugMode) {
      debugPrint('[ScreenShare] calling setScreenShareEnabled (mobile/android)');
    }
    final pub = await participant.setScreenShareEnabled(
      true,
      screenShareCaptureOptions: _webCaptureOptions,
    );
    if (pub is! LocalTrackPublication<LocalVideoTrack>) return null;
    if (pub.track == null) return null;
    if (kDebugMode) {
      debugPrint('[ScreenShare] mobile publish success, sid=${pub.sid}');
    }
    _attachOnEnded(pub.track!, onEnded);
    return pub;
  }

  static Future<LocalTrackPublication<LocalVideoTrack>?> _startWeb(
    LocalParticipant participant,
    ScreenShareEndedCallback? onEnded,
  ) async {
    if (kDebugMode) {
      debugPrint('[ScreenShare] Web: unpublishing existing screen tracks');
    }
    await unpublishScreenTracks(participant);

    final pausedCamera = await _pauseCameraForWebShare(participant);
    if (kDebugMode) {
      debugPrint('[ScreenShare] Web: camera paused=$pausedCamera');
    }
    LocalVideoTrack? track;

    try {
      LocalTrackPublication<LocalVideoTrack>? pub;
      try {
        if (kDebugMode) {
          debugPrint('[ScreenShare] Web: calling setScreenShareEnabled');
        }
        pub = await participant.setScreenShareEnabled(
          true,
          screenShareCaptureOptions: _webCaptureOptions,
        ) as LocalTrackPublication<LocalVideoTrack>?;
        if (kDebugMode && pub != null) {
          debugPrint('[ScreenShare] Web: setScreenShareEnabled success, sid=${pub.sid}');
        }
      } catch (captureError) {
        if (kDebugMode) {
          debugPrint(
            '[ScreenShare] Web: setScreenShareEnabled failed, trying relaxed getDisplayMedia: '
            '$captureError',
          );
        }
        if (kDebugMode) {
          debugPrint('[ScreenShare] Web: calling getDisplayMedia (relaxed)');
        }
        track = await _createRelaxedWebScreenTrack();
        if (kDebugMode) {
          debugPrint('[ScreenShare] Web: getDisplayMedia success, track sid=${track.sid}');
        }
        _attachOnEnded(track, onEnded);
        if (kDebugMode) {
          debugPrint('[ScreenShare] Web: calling publishVideoTrack');
        }
        pub = await participant.publishVideoTrack(
          track,
          publishOptions: _screenSharePublishOptions,
        );
        if (kDebugMode) {
          debugPrint('[ScreenShare] Web: publishVideoTrack success, sid=${pub.sid}');
        }
      }

      if (pub == null || pub.track == null) {
        if (kDebugMode) {
          debugPrint('[ScreenShare] Web: publication or track is null, cleaning up');
        }
        if (track != null) {
          await _stopLocalTrack(track);
        }
        if (pausedCamera) {
          await _enableCamera(participant);
        }
        return null;
      }

      if (pausedCamera) {
        _pausedCameraForWebShare = true;
      }
      _attachOnEnded(pub.track!, onEnded);
      if (kDebugMode) {
        debugPrint('[ScreenShare] Web: start complete, publication sid=${pub.sid}, track sid=${pub.track!.sid}');
      }
      return pub;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScreenShare] Web: exception during start: $e');
      }
      if (track != null) {
        await _stopLocalTrack(track);
      }
      if (pausedCamera) {
        await _enableCamera(participant);
      }
      rethrow;
    }
  }

  static Future<LocalVideoTrack> _createRelaxedWebScreenTrack() async {
    final stream = await rtc.navigator.mediaDevices.getDisplayMedia({
      'video': true,
      'audio': false,
    });
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      await _stopMediaStream(stream);
      throw Exception('getDisplayMedia returned no video track');
    }
    // ignore: invalid_use_of_internal_member
    return LocalVideoTrack(
      TrackSource.screenShareVideo,
      stream,
      tracks.first,
      _webCaptureOptions,
    );
  }

  static Future<LocalTrackPublication<LocalVideoTrack>?> _startDesktop(
    LocalParticipant participant,
    BuildContext context,
    ScreenShareEndedCallback? onEnded,
  ) async {
    if (!context.mounted) return null;
    if (kDebugMode) {
      debugPrint('[ScreenShare] Desktop: showing ScreenSelectDialog');
    }
    final source = await showDialog<rtc.DesktopCapturerSource>(
      context: context,
      builder: (dialogContext) => ScreenSelectDialog(),
    );
    if (source == null) {
      if (kDebugMode) {
        debugPrint('[ScreenShare] Desktop: user cancelled source selection');
      }
      return null;
    }
    if (kDebugMode) {
      debugPrint('[ScreenShare] Desktop: source selected, id=${source.id}, name=${source.name}');
    }

    LocalVideoTrack? track;
    try {
      if (kDebugMode) {
        debugPrint('[ScreenShare] Desktop: calling createScreenShareTrack');
      }
      track = await LocalVideoTrack.createScreenShareTrack(
        ScreenShareCaptureOptions(
          sourceId: source.id,
          maxFrameRate: 15,
          captureScreenAudio: false,
        ),
      );
      if (kDebugMode) {
        debugPrint('[ScreenShare] Desktop: createScreenShareTrack success, track sid=${track.sid}');
      }
      _attachOnEnded(track, onEnded);
      if (kDebugMode) {
        debugPrint('[ScreenShare] Desktop: calling publishVideoTrack');
      }
      final pub = await participant.publishVideoTrack(
        track,
        publishOptions: _screenSharePublishOptions,
      );
      if (kDebugMode) {
        debugPrint('[ScreenShare] Desktop: publishVideoTrack success, sid=${pub.sid}');
      }
      return pub;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScreenShare] Desktop: exception during start: $e');
      }
      if (track != null) {
        await _stopLocalTrack(track);
      }
      rethrow;
    }
  }

  static void _attachOnEnded(
    LocalVideoTrack track,
    ScreenShareEndedCallback? onEnded,
  ) {
    track.mediaStreamTrack.onEnded = () {
      if (onEnded != null) {
        unawaited(onEnded());
      }
    };
  }

  static Future<void> _stopLocalTrack(LocalVideoTrack track) async {
    try {
      await track.stop();
    } catch (_) {}
  }

  static Future<void> _stopMediaStream(rtc.MediaStream stream) async {
    for (final t in stream.getTracks()) {
      try {
        await t.stop();
      } catch (_) {}
    }
  }
}
