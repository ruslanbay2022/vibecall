import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart';

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
  /// Capture runs as the first await (user-gesture). No unpublish before capture.
  static Future<LocalTrackPublication<LocalVideoTrack>?> start(
    LocalParticipant participant, {
    BuildContext? context,
    ScreenShareEndedCallback? onEnded,
  }) async {
    if (lkPlatformIsDesktop() && context != null) {
      return _startDesktop(participant, context, onEnded);
    }
    if (kIsWeb) {
      return _startWeb(participant, onEnded);
    }
    await unpublishScreenTracks(participant);
    final pub = await participant.setScreenShareEnabled(
      true,
      screenShareCaptureOptions: _webCaptureOptions,
    );
    if (pub is! LocalTrackPublication<LocalVideoTrack>) return null;
    if (pub.track == null) return null;
    _attachOnEnded(pub.track!, onEnded);
    return pub;
  }

  static Future<LocalTrackPublication<LocalVideoTrack>?> _startWeb(
    LocalParticipant participant,
    ScreenShareEndedCallback? onEnded,
  ) async {
    LocalVideoTrack? track;
    try {
      try {
        track = await LocalVideoTrack.createScreenShareTrack(_webCaptureOptions);
      } catch (captureError) {
        if (kDebugMode) {
          debugPrint(
            'createScreenShareTrack failed, trying relaxed getDisplayMedia: '
            '$captureError',
          );
        }
        track = await _createRelaxedWebScreenTrack();
      }

      _attachOnEnded(track, onEnded);

      return await participant.publishVideoTrack(
        track,
        publishOptions: _screenSharePublishOptions,
      );
    } catch (e) {
      if (track != null) {
        await _stopLocalTrack(track);
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

    LocalVideoTrack? track;
    try {
      track = await LocalVideoTrack.createScreenShareTrack(
        ScreenShareCaptureOptions(
          sourceId: source.id,
          maxFrameRate: 15,
          captureScreenAudio: false,
        ),
      );
      _attachOnEnded(track, onEnded);
      return await participant.publishVideoTrack(
        track,
        publishOptions: _screenSharePublishOptions,
      );
    } catch (e) {
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
