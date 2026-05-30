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
  final bool hasVideo;

  const CallStateActive({
    required this.room,
    required this.peer,
    this.hasVideo = true,
  });
}

class CallStateEnded extends CallState {
  final CallOutcome outcome;
  final int durationSec;

  const CallStateEnded({required this.outcome, this.durationSec = 0});
}

class CallStateError extends CallState {
  final String message;

  const CallStateError({required this.message});
}
