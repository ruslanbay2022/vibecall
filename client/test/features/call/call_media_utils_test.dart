import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:vibecall/features/call/presentation/widgets/call_media_utils.dart';

// Mock classes for testing
class MockParticipant implements Participant {
  final Map<TrackSource, TrackPublication> _publications = {};

  void addPublication(TrackSource source, TrackPublication pub) {
    _publications[source] = pub;
  }

  @override
  TrackPublication? getTrackPublicationBySource(TrackSource source) {
    return _publications[source];
  }

  // Implement other required methods with stubs
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockTrackPublication implements TrackPublication {
  @override
  final bool muted;
  @override
  final Track? track;

  MockTrackPublication({this.muted = false, this.track});

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockVideoTrack implements VideoTrack {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('isParticipantCameraOn', () {
    test('returns false when participant is null', () {
      expect(isParticipantCameraOn(null), isFalse);
    });

    test('returns false when no camera publication', () {
      final participant = MockParticipant();
      expect(isParticipantCameraOn(participant), isFalse);
    });

    test('returns false when camera publication is muted', () {
      final participant = MockParticipant();
      final pub = MockTrackPublication(muted: true);
      participant.addPublication(TrackSource.camera, pub);
      expect(isParticipantCameraOn(participant), isFalse);
    });

    test('returns true when camera publication is not muted', () {
      final participant = MockParticipant();
      final pub = MockTrackPublication(muted: false);
      participant.addPublication(TrackSource.camera, pub);
      expect(isParticipantCameraOn(participant), isTrue);
    });
  });

  group('participantCameraTrack', () {
    test('returns null when participant is null', () {
      expect(participantCameraTrack(null), isNull);
    });

    test('returns null when no camera publication', () {
      final participant = MockParticipant();
      expect(participantCameraTrack(participant), isNull);
    });

    test('returns null when camera publication is muted', () {
      final participant = MockParticipant();
      final track = MockVideoTrack();
      final pub = MockTrackPublication(muted: true, track: track);
      participant.addPublication(TrackSource.camera, pub);
      expect(participantCameraTrack(participant), isNull);
    });

    test('returns video track when camera publication is not muted', () {
      final participant = MockParticipant();
      final track = MockVideoTrack();
      final pub = MockTrackPublication(muted: false, track: track);
      participant.addPublication(TrackSource.camera, pub);
      expect(participantCameraTrack(participant), equals(track));
    });
  });

  group('isParticipantScreenSharing', () {
    test('returns false when participant is null', () {
      expect(isParticipantScreenSharing(null), isFalse);
    });

    test('returns false when no screen share publication', () {
      final participant = MockParticipant();
      expect(isParticipantScreenSharing(participant), isFalse);
    });

    test('returns false when screen share publication is muted', () {
      final participant = MockParticipant();
      final pub = MockTrackPublication(muted: true);
      participant.addPublication(TrackSource.screenShareVideo, pub);
      expect(isParticipantScreenSharing(participant), isFalse);
    });

    test('returns false when screen share publication has no video track', () {
      final participant = MockParticipant();
      final pub = MockTrackPublication(muted: false);
      participant.addPublication(TrackSource.screenShareVideo, pub);
      expect(isParticipantScreenSharing(participant), isFalse);
    });

    test('returns true when screen share has active video track', () {
      final participant = MockParticipant();
      final track = MockVideoTrack();
      final pub = MockTrackPublication(muted: false, track: track);
      participant.addPublication(TrackSource.screenShareVideo, pub);
      expect(isParticipantScreenSharing(participant), isTrue);
    });
  });

  group('participantScreenShareTrack', () {
    test('returns null when participant is null', () {
      expect(participantScreenShareTrack(null), isNull);
    });

    test('returns null when no screen share publication', () {
      final participant = MockParticipant();
      expect(participantScreenShareTrack(participant), isNull);
    });

    test('returns null when screen share publication is muted', () {
      final participant = MockParticipant();
      final track = MockVideoTrack();
      final pub = MockTrackPublication(muted: true, track: track);
      participant.addPublication(TrackSource.screenShareVideo, pub);
      expect(participantScreenShareTrack(participant), isNull);
    });

    test('returns video track when screen share publication is not muted', () {
      final participant = MockParticipant();
      final track = MockVideoTrack();
      final pub = MockTrackPublication(muted: false, track: track);
      participant.addPublication(TrackSource.screenShareVideo, pub);
      expect(participantScreenShareTrack(participant), equals(track));
    });
  });

  group('participantPrimaryRemoteVideoTrack', () {
    test('returns null when participant is null', () {
      expect(participantPrimaryRemoteVideoTrack(null), isNull);
    });

    test('returns screen share track when both are available', () {
      final participant = MockParticipant();
      final cameraTrack = MockVideoTrack();
      final screenTrack = MockVideoTrack();
      final cameraPub = MockTrackPublication(muted: false, track: cameraTrack);
      final screenPub = MockTrackPublication(muted: false, track: screenTrack);
      participant.addPublication(TrackSource.camera, cameraPub);
      participant.addPublication(TrackSource.screenShareVideo, screenPub);
      expect(participantPrimaryRemoteVideoTrack(participant), equals(screenTrack));
    });

    test('returns camera track when only camera is available', () {
      final participant = MockParticipant();
      final cameraTrack = MockVideoTrack();
      final cameraPub = MockTrackPublication(muted: false, track: cameraTrack);
      participant.addPublication(TrackSource.camera, cameraPub);
      expect(participantPrimaryRemoteVideoTrack(participant), equals(cameraTrack));
    });

    test('returns screen share track when only screen share is available', () {
      final participant = MockParticipant();
      final screenTrack = MockVideoTrack();
      final screenPub = MockTrackPublication(muted: false, track: screenTrack);
      participant.addPublication(TrackSource.screenShareVideo, screenPub);
      expect(participantPrimaryRemoteVideoTrack(participant), equals(screenTrack));
    });

    test('returns null when no tracks available', () {
      final participant = MockParticipant();
      expect(participantPrimaryRemoteVideoTrack(participant), isNull);
    });

    test('returns camera track when screen share is muted', () {
      final participant = MockParticipant();
      final cameraTrack = MockVideoTrack();
      final screenTrack = MockVideoTrack();
      final cameraPub = MockTrackPublication(muted: false, track: cameraTrack);
      final screenPub = MockTrackPublication(muted: true, track: screenTrack);
      participant.addPublication(TrackSource.camera, cameraPub);
      participant.addPublication(TrackSource.screenShareVideo, screenPub);
      expect(participantPrimaryRemoteVideoTrack(participant), equals(cameraTrack));
    });
  });
}
