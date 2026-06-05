import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/chat/data/conversation_dto.dart';
import 'package:vibecall/features/chat/data/message_dto.dart';
import 'package:vibecall/features/chat/domain/conversation.dart';
import 'package:vibecall/features/chat/domain/message.dart';

part 'chat_repository.g.dart';

abstract class ChatRepository {
  String get currentUserId;

  Future<String> ensureConversation(String otherUserId);
  Future<List<Message>> fetchMessages(
    String conversationId, {
    DateTime? beforeCursor,
    int limit = 50,
  });
  Future<List<Conversation>> fetchConversations();
  Future<Map<String, int>> fetchUnreadCountsByConversation();
  Future<void> sendMessage(String conversationId, String body);
  Future<void> markRead(String messageId);
  Stream<Message> messageStream(String conversationId);
  Stream<Message> globalIncomingMessageStream();
  Stream<List<Conversation>> conversationsStream();
}

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _client;
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, RealtimeChannel> _messageChannels = {};
  StreamController<List<Conversation>>? _conversationsController;
  final List<RealtimeChannel> _conversationsChannels = [];
  StreamController<Message>? _globalIncomingController;

  SupabaseChatRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  String get currentUserId => _client.auth.currentUser!.id;

  @override
  Future<String> ensureConversation(String otherUserId) async {
    final response = await _client.rpc(
      'ensure_conversation',
      params: {'p_other': otherUserId},
    );
    return response as String;
  }

  @override
  Future<List<Message>> fetchMessages(
    String conversationId, {
    DateTime? beforeCursor,
    int limit = 50,
  }) async {
    var query = _client
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId);

    if (beforeCursor != null) {
      query = query.lt('created_at', beforeCursor.toUtc().toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = (response as List)
        .map((e) => MessageDto.fromJson(e as Map<String, dynamic>)
            .toDomain(currentUserId: currentUserId))
        .toList();

    return messages.reversed.toList();
  }

  @override
  Future<List<Conversation>> fetchConversations() async {
    final userId = currentUserId;
    final response = await _client
        .from('conversations')
        .select(
          'id, user_a, user_b, last_message_at, created_at, '
          'peer_a:profiles!conversations_user_a_fkey(username, display_name, avatar_url), '
          'peer_b:profiles!conversations_user_b_fkey(username, display_name, avatar_url), '
          'messages(body, created_at).order(created_at.desc).limit(1)',
        )
        .or('user_a.eq.$userId,user_b.eq.$userId')
        .order('last_message_at', ascending: false);

    final unreadCounts = await fetchUnreadCountsByConversation();

    return (response as List)
        .map((e) => ConversationDto.fromJson(e as Map<String, dynamic>)
            .toDomain(
              currentUserId: userId,
              unreadCountsByConversation: unreadCounts,
            ))
        .toList();
  }

  @override
  Future<Map<String, int>> fetchUnreadCountsByConversation() async {
    final userId = currentUserId;
    final response = await _client
        .from('messages')
        .select('conversation_id')
        .isFilter('read_at', null)
        .neq('sender_id', userId);

    final counts = <String, int>{};
    for (final row in response as List) {
      final map = row as Map<String, dynamic>;
      final convId = map['conversation_id'] as String;
      counts[convId] = (counts[convId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<void> sendMessage(String conversationId, String body) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'body': body,
    });
  }

  @override
  Future<void> markRead(String messageId) async {
    await _client.from('messages').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', messageId);
  }

  @override
  Stream<Message> messageStream(String conversationId) {
    _messageControllers[conversationId]?.close();
    _messageChannels[conversationId]?.unsubscribe();

    final controller = StreamController<Message>.broadcast(
      onCancel: () {
        _messageChannels[conversationId]?.unsubscribe();
        _messageChannels.remove(conversationId);
        _messageControllers.remove(conversationId);
      },
    );
    _messageControllers[conversationId] = controller;

    final channel = _client.channel('chat:messages:$conversationId');
    _messageChannels[conversationId] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final record = payload.newRecord;
              final dto = MessageDto.fromJson(record);
              controller.add(dto.toDomain(currentUserId: currentUserId));
            } catch (_) {}
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final record = payload.newRecord;
              final dto = MessageDto.fromJson(record);
              controller.add(dto.toDomain(currentUserId: currentUserId));
            } catch (_) {}
          },
        )
        .subscribe();

    return controller.stream;
  }

  @override
  Stream<Message> globalIncomingMessageStream() {
    final existing = _globalIncomingController;
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    final controller = StreamController<Message>.broadcast();
    _globalIncomingController = controller;

    _client
        .channel('chat:global-incoming')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            try {
              final record = payload.newRecord;
              final dto = MessageDto.fromJson(record);
              controller.add(dto.toDomain(currentUserId: currentUserId));
            } catch (_) {}
          },
        )
        .subscribe();

    return controller.stream;
  }

  @override
  Stream<List<Conversation>> conversationsStream() {
    _conversationsController?.close();
    for (final ch in _conversationsChannels) {
      ch.unsubscribe();
    }
    _conversationsChannels.clear();

    final controller = StreamController<List<Conversation>>.broadcast(
      onCancel: () {
        for (final ch in _conversationsChannels) {
          ch.unsubscribe();
        }
        _conversationsChannels.clear();
        _conversationsController = null;
      },
    );
    _conversationsController = controller;

    final userId = currentUserId;

    Future<void> refresh() async {
      try {
        final conversations = await fetchConversations();
        controller.add(conversations);
      } catch (_) {}
    }

    refresh();

    final channelA = _client.channel('chat:conversations:a:$userId');
    _conversationsChannels.add(channelA);
    channelA
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_a',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe();

    final channelB = _client.channel('chat:conversations:b:$userId');
    _conversationsChannels.add(channelB);
    channelB
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_b',
            value: userId,
          ),
          callback: (_) => refresh(),
        )
        .subscribe();

    return controller.stream;
  }
}

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return SupabaseChatRepository();
}
