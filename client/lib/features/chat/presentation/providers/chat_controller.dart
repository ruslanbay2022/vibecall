import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_typing_provider.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

part 'chat_controller.g.dart';

@riverpod
class ChatController extends _$ChatController {
  static const _pageSize = 50;

  StreamSubscription<Message>? _msgSub;
  StreamSubscription<String>? _typingSub;
  DateTime? _lastTypingSent;
  bool _isLoadingOlder = false;
  bool _hasMore = true;

  @override
  Future<List<Message>> build(String conversationId) async {
    final repo = ref.watch(chatRepositoryProvider);
    final typing = ref.watch(chatTypingProvider);

    _cleanup();

    Future.microtask(() {
      if (!ref.mounted) return;
      ref.read(activeChatConversationProvider.notifier).set(conversationId);
      ref
          .read(unreadCountsControllerProvider.notifier)
          .clearForConversation(conversationId);
    });

    ref.onDispose(() {
      _cleanup();
      try {
        typing.disposeTyping(conversationId);
      } catch (_) {}
      final activeNotifier = ref.read(activeChatConversationProvider.notifier);
      final unreadNotifier = ref.read(unreadCountsControllerProvider.notifier);
      final id = conversationId;
      Future.microtask(() {
        if (activeNotifier.state == id) {
          activeNotifier.set(null);
        }
        unreadNotifier.refresh();
      });
    });

    final messages = await repo.fetchMessages(conversationId, limit: _pageSize);
    _hasMore = messages.length >= _pageSize;

    _msgSub = repo.messageStream(conversationId).listen(
      (message) {
        final current = state.value ?? [];
        final idx = current.indexWhere((m) => m.id == message.id);
        if (idx >= 0) {
          final updated = List<Message>.of(current)..[idx] = message;
          state = AsyncValue.data(updated);
        } else {
          state = AsyncValue.data([...current, message]);
        }
        if (!message.isFromMe && message.readAt == null) {
          unawaited(repo.markRead(message.id));
        }
      },
      onError: (_) {},
    );

    _typingSub = typing.peerTypingStream(conversationId).listen(
      (peerId) {
        ref.read(chatTypingIndicatorProvider(conversationId).notifier).show();
      },
      onError: (_) {},
    );

    _markUnreadAsRead(repo, messages);

    return messages;
  }

  void _cleanup() {
    _msgSub?.cancel();
    _msgSub = null;
    _typingSub?.cancel();
    _typingSub = null;
  }

  void _markUnreadAsRead(ChatRepository repo, List<Message> messages) {
    for (final m in messages) {
      if (!m.isFromMe && m.readAt == null) {
        unawaited(repo.markRead(m.id));
      }
    }
  }

  Future<void> sendMessage(String body) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(conversationId, body);
  }

  Future<void> loadOlder() async {
    if (_isLoadingOlder || !_hasMore) return;
    final messages = state.value;
    if (messages == null || messages.isEmpty) return;

    _isLoadingOlder = true;
    try {
      final repo = ref.read(chatRepositoryProvider);
      final oldest = messages.first;
      final older = await repo.fetchMessages(
        conversationId,
        beforeCursor: oldest.createdAt,
        limit: _pageSize,
      );
      _hasMore = older.length >= _pageSize;
      final current = state.value ?? [];
      final merged = <String, Message>{};
      for (final m in [...older, ...current]) {
        merged[m.id] = m;
      }
      final result = merged.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncValue.data(result);
    } finally {
      _isLoadingOlder = false;
    }
  }

  void onTextChanged() {
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastTypingSent = now;
    final typing = ref.read(chatTypingProvider);
    typing.notifyTyping(conversationId);
  }
}

@riverpod
class ChatTypingIndicator extends _$ChatTypingIndicator {
  Timer? _timer;

  @override
  bool build(String conversationId) {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void show() {
    _timer?.cancel();
    state = true;
    _timer = Timer(const Duration(seconds: 3), () {
      state = false;
    });
  }
}
