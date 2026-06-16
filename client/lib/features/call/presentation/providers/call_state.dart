import 'package:livekit_client/livekit_client.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';

sealed class CallState {
  const CallState();
}

class CallStateIdle extends CallState {
  const CallStateIdle();
}

class CallStateOutgoing extends CallState {
  final String roomName;
  final String receiverId;

  const CallStateOutgoing({required this.roomName, required this.receiverId});
}

class CallStateIncoming extends CallState {
  final CallInvitation invitation;

  const CallStateIncoming({required this.invitation});
}

class CallStateConnecting extends CallState {
  const CallStateConnecting();
}

class CallStateActive extends CallState {
  final Room room;
  final RemoteParticipant peer;
  final String peerUserId;
  final bool hasVideo;
  final int mediaTick;

  const CallStateActive({
    required this.room,
    required this.peer,
    required this.peerUserId,
    this.hasVideo = true,
    this.mediaTick = 0,
  });
}

class CallStateEnded extends CallState {
  final CallOutcome outcome;
  final int durationSec;

  const CallStateEnded({required this.outcome, this.durationSec = 0});
}

/// [CallStateError.message] sentinel — map to [AppLocalizations.callMediaPermissionRequired] in UI.
const callMediaPermissionDeniedMessageId = 'call_media_permission_denied';

class CallStateError extends CallState {
  final String message;

  const CallStateError({required this.message});
}
