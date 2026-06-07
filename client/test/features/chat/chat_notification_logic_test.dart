import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/chat/domain/chat_peer.dart';
import 'package:vibecall/features/chat/domain/conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_notification_logic.dart';

void main() {
  group('shouldPlayMessageSound', () {
    const currentUserId = 'user-a';
    const otherUserId = 'user-b';
    const messageId = 'msg-1';
    test('returns false when sender is current user', () {
      final result = shouldPlayMessageSound(
        senderId: currentUserId,
        currentUserId: currentUserId,
        messageId: messageId,
        recentMessageIds: {},
        readAt: null,
      );
      expect(result, isFalse);
    });

    test('returns false when message is already read', () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        messageId: messageId,
        recentMessageIds: {},
        readAt: DateTime(2024, 1, 1),
      );
      expect(result, isFalse);
    });

    test('returns true when user is viewing the same conversation', () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        messageId: messageId,
        recentMessageIds: {},
        readAt: null,
      );
      expect(result, isTrue);
    });

    test('returns false when message id is in recent ids (duplicate)', () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        messageId: messageId,
        recentMessageIds: {messageId},
        readAt: null,
      );
      expect(result, isFalse);
    });

    test('returns true for incoming message from other user in different chat',
        () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        messageId: messageId,
        recentMessageIds: {},
        readAt: null,
      );
      expect(result, isTrue);
    });

    test('returns true for incoming message when no active chat', () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        messageId: messageId,
        recentMessageIds: {},
        readAt: null,
      );
      expect(result, isTrue);
    });
  });

  group('mapUnreadCountsByPeerUserId', () {
    Conversation conv(String id, String peerId, {int unread = 0}) {
      return Conversation(
        id: id,
        lastMessageAt: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        peer: ChatPeer(id: peerId),
        unreadCount: unread,
      );
    }

    test('returns empty map when no unread conversations', () {
      final result = mapUnreadCountsByPeerUserId(
        unreadByConversationId: {},
        conversations: [conv('conv-1', 'peer-1')],
        activeConversationId: null,
      );
      expect(result, isEmpty);
    });

    test('maps unread count to peer user id', () {
      final result = mapUnreadCountsByPeerUserId(
        unreadByConversationId: {'conv-1': 3},
        conversations: [conv('conv-1', 'peer-1')],
        activeConversationId: null,
      );
      expect(result, {'peer-1': 3});
    });

    test('zeros count for active conversation', () {
      final result = mapUnreadCountsByPeerUserId(
        unreadByConversationId: {'conv-1': 2},
        conversations: [conv('conv-1', 'peer-1')],
        activeConversationId: 'conv-1',
      );
      expect(result, isEmpty);
    });

    test('ignores contact without matching conversation', () {
      final result = mapUnreadCountsByPeerUserId(
        unreadByConversationId: {'conv-2': 1},
        conversations: [conv('conv-1', 'peer-1')],
        activeConversationId: null,
      );
      expect(result, isEmpty);
    });
  });

  group('aggregateUnreadCounts', () {
    const currentUserId = 'user-a';
    const otherUserId = 'user-b';

    test('returns empty map for empty messages', () {
      final result = aggregateUnreadCounts([], currentUserId);
      expect(result, isEmpty);
    });

    test('ignores messages from current user', () {
      final messages = [
        {
          'sender_id': currentUserId,
          'conversation_id': 'conv-1',
          'read_at': null,
        },
      ];
      final result = aggregateUnreadCounts(messages, currentUserId);
      expect(result, isEmpty);
    });

    test('ignores read messages', () {
      final messages = [
        {
          'sender_id': otherUserId,
          'conversation_id': 'conv-1',
          'read_at': '2024-01-01T00:00:00Z',
        },
      ];
      final result = aggregateUnreadCounts(messages, currentUserId);
      expect(result, isEmpty);
    });

    test('counts unread messages from other users', () {
      final messages = [
        {
          'sender_id': otherUserId,
          'conversation_id': 'conv-1',
          'read_at': null,
        },
        {
          'sender_id': otherUserId,
          'conversation_id': 'conv-1',
          'read_at': null,
        },
      ];
      final result = aggregateUnreadCounts(messages, currentUserId);
      expect(result, {'conv-1': 2});
    });

    test('aggregates across multiple conversations', () {
      final messages = [
        {
          'sender_id': otherUserId,
          'conversation_id': 'conv-1',
          'read_at': null,
        },
        {
          'sender_id': otherUserId,
          'conversation_id': 'conv-2',
          'read_at': null,
        },
        {
          'sender_id': otherUserId,
          'conversation_id': 'conv-1',
          'read_at': null,
        },
      ];
      final result = aggregateUnreadCounts(messages, currentUserId);
      expect(result, {'conv-1': 2, 'conv-2': 1});
    });
  });
}
