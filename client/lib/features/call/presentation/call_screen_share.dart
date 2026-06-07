import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

typedef ScreenShareEndedCallback = Future<void> Function();

/// Starts local screen share with platform-appropriate capture UI.
class CallScreenShare {
  CallScreenShare._();

  /// Removes published screen-share tracks (video + tab audio if any).
  static Future<void> unpublishScreenTracks(LocalParticipant participant) async {
    final screenPub =
        participant.getTrackPublicationBySource(TrackSource.screenShareVideo);
    if (screenPub != null) {
      await participant.removePublishedTrack(screenPub.sid);
    }
    final audioPub =
        participant.getTrackPublicationBySource(TrackSource.screenShareAudio);
    if (audioPub != null) {
      await participant.removePublishedTrack(audioPub.sid);
    }
  }

  /// Web: relaxed `getDisplayMedia({video: true})` (fixes Edge / strict constraints).
  /// Windows/macOS/Linux desktop: [ScreenSelectDialog] with all screens/windows.
  /// Android: LiveKit [LocalParticipant.setScreenShareEnabled].
  ///
  /// **User-gesture rule:** on Web/desktop the system picker / getDisplayMedia runs
  /// before any unpublish await so Edge does not lose transient activation.
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
    await unpublishScreenTracks(participant);
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
    // Must be the first await — Edge rejects getDisplayMedia after other awaits.
    final stream = await rtc.navigator.mediaDevices.getDisplayMedia({
      'video': true,
      'audio': false,
    });
    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) {
      throw Exception('getDisplayMedia returned no video track');
    }
    final mediaTrack = tracks.first;

    await unpublishScreenTracks(participant);

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
    // Picker first — same user-gesture rule as Web getDisplayMedia.
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

    await unpublishScreenTracks(participant);

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
