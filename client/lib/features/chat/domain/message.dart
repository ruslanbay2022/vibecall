class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;
  final bool isFromMe;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.readAt,
    required this.createdAt,
    required this.isFromMe,
  });
}
