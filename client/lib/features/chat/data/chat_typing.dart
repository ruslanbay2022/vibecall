import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatTyping {
  void notifyTyping(String conversationId);
  Stream<String> peerTypingStream(String conversationId);
  void disposeTyping(String conversationId);
}

class SupabaseChatTyping implements ChatTyping {
  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<String>> _controllers = {};

  SupabaseChatTyping({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  @override
  void notifyTyping(String conversationId) {
    final channel = _channels[conversationId];
    if (channel == null) return;
    channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'userId': _currentUserId},
    );
  }

  @override
  Stream<String> peerTypingStream(String conversationId) {
    _controllers[conversationId]?.close();
    _channels[conversationId]?.unsubscribe();

    final controller = StreamController<String>.broadcast(
      onCancel: () {
        _channels[conversationId]?.unsubscribe();
        _channels.remove(conversationId);
        _controllers.remove(conversationId);
      },
    );
    _controllers[conversationId] = controller;

    final channel = _client.channel('typing:$conversationId');
    _channels[conversationId] = channel;

    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['userId'] as String?;
        if (userId != null && userId != _currentUserId) {
          controller.add(userId);
        }
      },
    );

    channel.subscribe();

    return controller.stream;
  }

  @override
  void disposeTyping(String conversationId) {
    _channels[conversationId]?.unsubscribe();
    _channels.remove(conversationId);
    _controllers[conversationId]?.close();
    _controllers.remove(conversationId);
  }
}
