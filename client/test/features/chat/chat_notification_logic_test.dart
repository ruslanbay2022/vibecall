import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_notification_logic.dart';

void main() {
  group('shouldPlayMessageSound', () {
    const currentUserId = 'user-a';
    const otherUserId = 'user-b';
    const conversationId = 'conv-1';
    const messageId = 'msg-1';

    test('returns false when sender is current user', () {
      final result = shouldPlayMessageSound(
        senderId: currentUserId,
        currentUserId: currentUserId,
        conversationId: conversationId,
        activeConversationId: null,
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
        conversationId: conversationId,
        activeConversationId: null,
        messageId: messageId,
        recentMessageIds: {},
        readAt: DateTime(2024, 1, 1),
      );
      expect(result, isFalse);
    });

    test('returns false when active conversation matches message conversation',
        () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        conversationId: conversationId,
        activeConversationId: conversationId,
        messageId: messageId,
        recentMessageIds: {},
        readAt: null,
      );
      expect(result, isFalse);
    });

    test('returns false when message id is in recent ids (duplicate)', () {
      final result = shouldPlayMessageSound(
        senderId: otherUserId,
        currentUserId: currentUserId,
        conversationId: conversationId,
        activeConversationId: null,
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
        conversationId: conversationId,
        activeConversationId: 'other-conv',
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
        conversationId: conversationId,
        activeConversationId: null,
        messageId: messageId,
        recentMessageIds: {},
        readAt: null,
      );
      expect(result, isTrue);
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
