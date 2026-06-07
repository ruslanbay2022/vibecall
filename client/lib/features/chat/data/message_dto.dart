import 'package:vibecall/features/chat/domain/message.dart';

class MessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;

  MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.deliveredAt,
    required this.readAt,
    required this.createdAt,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory MessageDto.fromRealtime(Map<String, dynamic> payload) {
    final record = payload['new'] as Map<String, dynamic>?;
    if (record == null) {
      throw const FormatException('Realtime payload missing "new" record');
    }
    return MessageDto.fromJson(record);
  }

  Message toDomain({required String currentUserId}) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      deliveredAt: deliveredAt,
      readAt: readAt,
      createdAt: createdAt,
      isFromMe: senderId == currentUserId,
    );
  }
}
