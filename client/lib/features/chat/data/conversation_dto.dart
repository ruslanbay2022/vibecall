import 'package:vibecall/features/chat/domain/chat_peer.dart';
import 'package:vibecall/features/chat/domain/conversation.dart';

class ConversationDto {
  final String id;
  final String userA;
  final String userB;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final Map<String, dynamic>? peerAProfile;
  final Map<String, dynamic>? peerBProfile;
  final String? lastMessageBody;

  ConversationDto({
    required this.id,
    required this.userA,
    required this.userB,
    required this.lastMessageAt,
    required this.createdAt,
    this.peerAProfile,
    this.peerBProfile,
    this.lastMessageBody,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    String? lastBody;
    final messages = json['messages'] as List?;
    if (messages != null && messages.isNotEmpty) {
      Map<String, dynamic>? latest;
      DateTime? latestAt;
      for (final m in messages) {
        final msg = m as Map<String, dynamic>;
        final at = msg['created_at'] as String?;
        if (at == null) continue;
        final dt = DateTime.parse(at);
        if (latestAt == null || dt.isAfter(latestAt)) {
          latestAt = dt;
          latest = msg;
        }
      }
      lastBody = latest?['body'] as String?;
    }
    return ConversationDto(
      id: json['id'] as String,
      userA: json['user_a'] as String,
      userB: json['user_b'] as String,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      peerAProfile: json['peer_a'] as Map<String, dynamic>?,
      peerBProfile: json['peer_b'] as Map<String, dynamic>?,
      lastMessageBody: lastBody,
    );
  }

  Conversation toDomain({required String currentUserId}) {
    final isUserA = userA == currentUserId;
    final peerId = isUserA ? userB : userA;
    final peerProfile = isUserA ? peerBProfile : peerAProfile;

    final peer = ChatPeer(
      id: peerId,
      username: peerProfile?['username'] as String?,
      displayName: peerProfile?['display_name'] as String?,
      avatarUrl: peerProfile?['avatar_url'] as String?,
    );

    return Conversation(
      id: id,
      lastMessageAt: lastMessageAt,
      createdAt: createdAt,
      peer: peer,
      lastMessageBody: lastMessageBody,
    );
  }
}
