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
  if (participant == null) return false;
  final pub = participant.getTrackPublicationBySource(TrackSource.screenShareVideo);
  return pub != null && !pub.muted;
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
