import 'package:vibecall/features/call/data/call_invitation_dto.dart';

class CallInvitation {
  final String id;
  final String roomName;
  final String callerId;
  final String receiverId;
  final bool hasVideo;
  final String state;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? endedAt;

  CallInvitation({
    required this.id,
    required this.roomName,
    required this.callerId,
    required this.receiverId,
    required this.hasVideo,
    required this.state,
    required this.createdAt,
    required this.expiresAt,
    this.endedAt,
  });

  factory CallInvitation.fromDto(CallInvitationDto dto) => CallInvitation(
        id: dto.id,
        roomName: dto.roomName,
        callerId: dto.callerId,
        receiverId: dto.receiverId,
        hasVideo: dto.hasVideo,
        state: dto.state,
        createdAt: dto.createdAt,
        expiresAt: dto.expiresAt,
        endedAt: dto.endedAt,
      );
}
