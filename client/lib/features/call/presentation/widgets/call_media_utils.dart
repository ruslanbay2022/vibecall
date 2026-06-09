import 'package:livekit_client/livekit_client.dart';

bool isParticipantCameraOn(Participant? participant) {
  if (participant == null) return false;
  final pub = participant.getTrackPublicationBySource(TrackSource.camera);
  return pub != null && !pub.muted;
}

VideoTrack? participantCameraTrack(Participant? participant) {
  if (participant == null) return null;
  final pub = participant.getTrackPublicationBySource(TrackSource.camera);
  if (pub == null || pub.muted) return null;
  final track = pub.track;
  return track is VideoTrack ? track : null;
}

bool isParticipantScreenSharing(Participant? participant) {
  return participantScreenShareTrack(participant) != null;
}

VideoTrack? participantScreenShareTrack(Participant? participant) {
  if (participant == null) return null;
  final pub = participant.getTrackPublicationBySource(TrackSource.screenShareVideo);
  if (pub == null || pub.muted) return null;
  final track = pub.track;
  return track is VideoTrack ? track : null;
}

/// Returns primary remote video track: screen share takes priority over camera.
VideoTrack? participantPrimaryRemoteVideoTrack(Participant? participant) {
  return participantScreenShareTrack(participant) ??
      participantCameraTrack(participant);
}

/// Remote layout when peer has camera + screen: main + optional PiP.
class RemoteVideoLayout {
  const RemoteVideoLayout({this.main, this.pip});
  final VideoTrack? main;
  final VideoTrack? pip;
  bool get isDual => main != null && pip != null;
}

/// Default: main=screen, pip=camera. [swapped] exchanges them.
RemoteVideoLayout remoteVideoLayout(
  Participant? peer, {
  bool swapped = false,
}) {
  final screen = participantScreenShareTrack(peer);
  final camera = participantCameraTrack(peer);

  if (swapped) {
    return RemoteVideoLayout(
      main: camera ?? screen,
      pip: (camera != null && screen != null) ? screen : null,
    );
  }
  return RemoteVideoLayout(main: screen ?? camera, pip: screen != null ? camera : null);
}
