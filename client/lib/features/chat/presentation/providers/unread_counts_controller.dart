import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/active_chat_from_route.dart';
import 'package:vibecall/features/chat/presentation/in_call_open_chat_at_notify.dart';
import 'package:vibecall/features/chat/presentation/providers/in_call_open_chat.dart';

part 'unread_counts_controller.g.dart';

@Riverpod(keepAlive: true)
class UnreadCountsController extends _$UnreadCountsController {
  StreamSubscription<AuthState>? _authSub;

  @override
  Future<Map<String, int>> build() async {
    ref.watch(chatRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    _authSub?.cancel();
    _authSub = authRepo.authStateChanges.listen((authState) {
      if (authState.session != null) {
        unawaited(refresh());
      } else if (ref.mounted) {
        state = const AsyncValue.data({});
      }
    });
    ref.onDispose(() {
      _authSub?.cancel();
      _authSub = null;
    });

    if (authRepo.currentUser == null) {
      return {};
    }
    return ref.read(chatRepositoryProvider).fetchUnreadCountsByConversation();
  }

  void onIncomingMessage(Message message) {
    try {
      if (!ref.mounted) return;
      if (ref.read(authRepositoryProvider).currentUser == null) return;
      if (message.isFromMe) return;
      if (message.readAt != null) return;

      final activeId = activeChatConversationIdFromRoute();
      if (activeId == message.conversationId) return;

      final inCallId = inCallOpenChatConversationIdAtNotifyTime(
        ref.read(inCallOpenChatProvider),
      );
      if (inCallId == message.conversationId) return;

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
    if (ref.read(authRepositoryProvider).currentUser == null) {
      state = const AsyncValue.data({});
      return;
    }
    state = const AsyncValue.loading();
    state = AsyncValue.data(
      await ref.read(chatRepositoryProvider).fetchUnreadCountsByConversation(),
    );
  }
}
