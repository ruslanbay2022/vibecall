import 'package:vibecall/features/chat/domain/chat_peer.dart';

class Conversation {
  final String id;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final ChatPeer peer;

  const Conversation({
    required this.id,
    required this.lastMessageAt,
    required this.createdAt,
    required this.peer,
  });
}
