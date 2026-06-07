class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isFromMe;
  final bool isPending;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.deliveredAt,
    required this.readAt,
    required this.createdAt,
    required this.isFromMe,
    this.isPending = false,
  });
}
