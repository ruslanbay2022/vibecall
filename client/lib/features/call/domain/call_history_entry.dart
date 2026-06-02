import 'package:vibecall/features/call/domain/call_outcome.dart';

class CallPeer {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const CallPeer({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });
}

class CallHistoryEntry {
  final String id;
  final String roomName;
  final String callerId;
  final String receiverId;
  final CallOutcome outcome;
  final bool hasVideo;
  final int durationSec;
  final DateTime startedAt;
  final DateTime? endedAt;
  final CallPeer peer;
  final bool isOutgoing;

  const CallHistoryEntry({
    required this.id,
    required this.roomName,
    required this.callerId,
    required this.receiverId,
    required this.outcome,
    required this.hasVideo,
    required this.durationSec,
    required this.startedAt,
    required this.endedAt,
    required this.peer,
    required this.isOutgoing,
  });

  String get displayName => peer.displayName ?? peer.username ?? '';
  String get handle => peer.username != null ? '@${peer.username}' : '';
}
