import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';

part 'unread_counts_controller.g.dart';

@Riverpod(keepAlive: true)
class UnreadCountsController extends _$UnreadCountsController {
  StreamSubscription<Message>? _subscription;
  String? _activeConversationId;
  var _listening = false;

  @override
  Future<Map<String, int>> build() async {
    final repo = ref.watch(chatRepositoryProvider);

    ref.listen(activeChatConversationProvider, (_, next) {
      _activeConversationId = next;
    });
    _activeConversationId = ref.read(activeChatConversationProvider);

    if (!_listening) {
      _listening = true;
      _subscription = repo.globalIncomingMessageStream().listen(
        _onIncomingMessage,
        onError: (error, stackTrace) {
          debugPrint('unread counts stream error: $error\n$stackTrace');
        },
      );
    }

    ref.onDispose(() {
      _listening = false;
      _subscription?.cancel();
      _subscription = null;
    });

    return repo.fetchUnreadCountsByConversation();
  }

  void _onIncomingMessage(Message message) {
    try {
      if (!ref.mounted) return;
      if (message.isFromMe) return;
      if (message.readAt != null) return;
      if (_activeConversationId == message.conversationId) return;

      final current = state.value ?? {};
      final updated = Map<String, int>.from(current);
      updated[message.conversationId] =
          (updated[message.conversationId] ?? 0) + 1;
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      debugPrint('unread counts handler failed: $e\n$stackTrace');
    }
  }

  void clearForConversation(String conversationId) {
    if (!ref.mounted) return;
    final current = state.value ?? {};
    if (!current.containsKey(conversationId)) return;
    final updated = Map<String, int>.from(current);
    updated.remove(conversationId);
    state = AsyncValue.data(updated);
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(chatRepositoryProvider).fetchUnreadCountsByConversation(),
    );
  }
}
