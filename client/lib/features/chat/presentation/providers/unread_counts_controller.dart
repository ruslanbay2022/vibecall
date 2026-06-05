import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';

part 'unread_counts_controller.g.dart';

@Riverpod(keepAlive: true)
class UnreadCountsController extends _$UnreadCountsController {
  @override
  Future<Map<String, int>> build() async {
    ref.watch(chatRepositoryProvider);
    return ref.read(chatRepositoryProvider).fetchUnreadCountsByConversation();
  }

  void onIncomingMessage(Message message) {
    try {
      if (!ref.mounted) return;
      if (message.isFromMe) return;
      if (message.readAt != null) return;

      final activeId = ref.read(activeChatConversationProvider);
      if (activeId == message.conversationId) return;

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
