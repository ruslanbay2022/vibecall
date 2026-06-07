bool shouldPlayMessageSound({
  required String senderId,
  required String currentUserId,
  required String messageId,
  required Set<String> recentMessageIds,
  required DateTime? readAt,
}) {
  if (senderId == currentUserId) return false;
  if (readAt != null) return false;
  if (recentMessageIds.contains(messageId)) return false;
  return true;
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
