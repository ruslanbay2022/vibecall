import 'package:vibecall/features/chat/domain/conversation.dart';

bool shouldPlayMessageSound({
  required String senderId,
  required String currentUserId,
  required String messageId,
  required Set<String> recentMessageIds,
  required DateTime? readAt,
  String? inCallConversationId,
  required String messageConversationId,
}) {
  if (senderId == currentUserId) return false;
  if (readAt != null) return false;
  if (recentMessageIds.contains(messageId)) return false;
  if (inCallConversationId == messageConversationId) return false;
  return true;
}

Map<String, int> mapUnreadCountsByPeerUserId({
  required Map<String, int> unreadByConversationId,
  required List<Conversation> conversations,
  required String? activeConversationId,
}) {
  final result = <String, int>{};
  for (final conversation in conversations) {
    final raw = unreadByConversationId[conversation.id] ?? 0;
    if (raw <= 0) continue;
    final count = activeConversationId == conversation.id ? 0 : raw;
    if (count > 0) {
      result[conversation.peer.id] = count;
    }
  }
  return result;
}

Map<String, int> aggregateUnreadCounts(
  List<Map<String, dynamic>> messages,
  String currentUserId,
) {
  final counts = <String, int>{};
  for (final msg in messages) {
    final senderId = msg['sender_id'] as String?;
    final conversationId = msg['conversation_id'] as String?;
    final readAt = msg['read_at'];
    if (senderId == null || conversationId == null) continue;
    if (senderId == currentUserId) continue;
    if (readAt != null) continue;
    counts[conversationId] = (counts[conversationId] ?? 0) + 1;
  }
  return counts;
}
