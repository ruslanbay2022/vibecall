import 'package:vibecall/features/call/domain/call_history_entry.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';

class CallHistoryDto {
  final String id;
  final String roomName;
  final String callerId;
  final String receiverId;
  final String outcome;
  final bool hasVideo;
  final int durationSec;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic>? callerProfile;
  final Map<String, dynamic>? receiverProfile;

  CallHistoryDto({
    required this.id,
    required this.roomName,
    required this.callerId,
    required this.receiverId,
    required this.outcome,
    required this.hasVideo,
    required this.durationSec,
    required this.startedAt,
    required this.endedAt,
    this.callerProfile,
    this.receiverProfile,
  });

  factory CallHistoryDto.fromJson(Map<String, dynamic> json) {
    return CallHistoryDto(
      id: json['id'] as String,
      roomName: json['room_name'] as String,
      callerId: json['caller_id'] as String,
      receiverId: json['receiver_id'] as String,
      outcome: json['outcome'] as String,
      hasVideo: json['has_video'] as bool,
      durationSec: json['duration_sec'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      callerProfile: json['caller'] as Map<String, dynamic>?,
      receiverProfile: json['receiver'] as Map<String, dynamic>?,
    );
  }

  CallHistoryEntry toDomain({required String currentUserId}) {
    final isOutgoing = callerId == currentUserId;
    final peerProfile = isOutgoing ? receiverProfile : callerProfile;
    final peer = CallPeer(
      id: isOutgoing ? receiverId : callerId,
      username: peerProfile?['username'] as String?,
      displayName: peerProfile?['display_name'] as String?,
      avatarUrl: peerProfile?['avatar_url'] as String?,
    );
    return CallHistoryEntry(
      id: id,
      roomName: roomName,
      callerId: callerId,
      receiverId: receiverId,
      outcome: _parseOutcome(outcome),
      hasVideo: hasVideo,
      durationSec: durationSec,
      startedAt: startedAt,
      endedAt: endedAt,
      peer: peer,
      isOutgoing: isOutgoing,
    );
  }

  static CallOutcome _parseOutcome(String raw) {
    return CallOutcome.values.firstWhere(
      (o) => o.name == raw,
      orElse: () => CallOutcome.missed,
    );
  }
}
