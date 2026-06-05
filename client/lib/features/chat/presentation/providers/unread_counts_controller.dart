import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';

part 'unread_counts_controller.g.dart';

@riverpod
class UnreadCountsController extends _$UnreadCountsController {
  StreamSubscription? _subscription;

  @override
  Future<Map<String, int>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    final counts = await repo.fetchUnreadCountsByConversation();

    _subscription?.cancel();
    _subscription = repo.globalIncomingMessageStream().listen(
      (message) {
        if (message.isFromMe) return;
        if (message.readAt != null) return;
        final activeId = ref.read(activeChatConversationProvider);
        if (activeId == message.conversationId) return;
        final current = state.value ?? {};
        final updated = Map<String, int>.from(current);
        updated[message.conversationId] =
            (updated[message.conversationId] ?? 0) + 1;
        state = AsyncValue.data(updated);
      },
      onError: (_) {},
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return counts;
  }

  void clearForConversation(String conversationId) {
    final current = state.value ?? {};
    if (!current.containsKey(conversationId)) return;
    final updated = Map<String, int>.from(current);
    updated.remove(conversationId);
    state = AsyncValue.data(updated);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
