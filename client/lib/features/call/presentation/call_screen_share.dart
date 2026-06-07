import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

typedef ScreenShareEndedCallback = Future<void> Function();

/// Starts local screen share with platform-appropriate capture UI.
class CallScreenShare {
  CallScreenShare._();

  /// Web: relaxed `getDisplayMedia({video: true})` (fixes Edge / strict constraints).
  /// Windows/macOS/Linux desktop: [ScreenSelectDialog] with all screens/windows.
  /// Android: LiveKit [LocalParticipant.setScreenShareEnabled].
  static Future<LocalTrackPublication<LocalVideoTrack>?> start(
    LocalParticipant participant, {
    BuildContext? context,
    ScreenShareEndedCallback? onEnded,
  }) async {
    if (lkPlatformIsDesktop() && context != null) {
      return _startDesktop(participant, context);
    }
    if (kIsWeb) {
      return _startWeb(participant, onEnded);
    }
    final pub = await participant.setScreenShareEnabled(
      true,
      screenShareCaptureOptions: const ScreenShareCaptureOptions(
        captureScreenAudio: false,
        preferCurrentTab: false,
      ),
    );
    if (pub is! LocalTrackPublication<LocalVideoTrack>) return null;
    if (pub.track == null) return null;
    return pub;
  }

  static Future<LocalTrackPublication<LocalVideoTrack>?> _startWeb(
    LocalParticipant participant,
    ScreenShareEndedCallback? onEnded,
  ) async {
    // Relaxed constraints — LiveKit defaults use 1080p map that breaks Edge Web.
    final stream = await rtc.navigator.mediaDevices.getDisplayMedia({
      'video': true,
      'audio': false,
    });
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      throw Exception('getDisplayMedia returned no video track');
    }
    final mediaTrack = tracks.first;
    // ignore: invalid_use_of_internal_member
    final track = LocalVideoTrack(
      TrackSource.screenShareVideo,
      stream,
      mediaTrack,
      const ScreenShareCaptureOptions(),
    );
    mediaTrack.onEnded = () {
      if (onEnded != null) {
        unawaited(onEnded());
      }
    };
    return participant.publishVideoTrack(track);
  }

  static Future<LocalTrackPublication<LocalVideoTrack>?> _startDesktop(
    LocalParticipant participant,
    BuildContext context,
  ) async {
    if (!context.mounted) return null;
    final source = await showDialog<rtc.DesktopCapturerSource>(
      context: context,
      builder: (dialogContext) => ScreenSelectDialog(),
    );
    if (source == null) {
      return null;
    }
    if (kDebugMode) {
      debugPrint('Screen share source: ${source.id} (${source.name})');
    }
    final track = await LocalVideoTrack.createScreenShareTrack(
      ScreenShareCaptureOptions(
        sourceId: source.id,
        maxFrameRate: 15,
        captureScreenAudio: false,
      ),
    );
    return participant.publishVideoTrack(track);
  }
}
