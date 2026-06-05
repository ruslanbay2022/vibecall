import 'package:vibecall/features/chat/domain/chat_peer.dart';

class Conversation {
  final String id;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final ChatPeer peer;
  final String? lastMessageBody;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.lastMessageAt,
    required this.createdAt,
    required this.peer,
    this.lastMessageBody,
    this.unreadCount = 0,
  });

  Conversation copyWith({int? unreadCount}) {
    return Conversation(
      id: id,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      peer: peer,
      lastMessageBody: lastMessageBody,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
