import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_typing_provider.dart';

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

    ref.onDispose(() {
      _cleanup();
      try {
        typing.disposeTyping(conversationId);
      } catch (_) {}
    });

    final messages = await repo.fetchMessages(conversationId, limit: _pageSize);
    _hasMore = messages.length >= _pageSize;

    _msgSub = repo.messageStream(conversationId).listen(
      (message) {
        _applyIncomingMessage(repo, message);
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

  void _applyIncomingMessage(ChatRepository repo, Message message) {
    var current = state.value ?? <Message>[];
    if (message.isFromMe) {
      current = current
          .where(
            (m) => !(m.isPending && m.body == message.body),
          )
          .toList();
    }
    final idx = current.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      current = List<Message>.of(current)..[idx] = message;
    } else {
      current = [...current, message];
    }
    state = AsyncValue.data(current);

    if (!message.isFromMe) {
      if (message.deliveredAt == null) {
        unawaited(repo.markDelivered(message.id));
      }
      if (message.readAt == null) {
        unawaited(repo.markRead(message.id));
      }
    }
  }

  Future<void> sendMessage(String body) async {
    final repo = ref.read(chatRepositoryProvider);
    final pending = Message(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: repo.currentUserId,
      body: body,
      readAt: null,
      createdAt: DateTime.now(),
      isFromMe: true,
      isPending: true,
    );
    final current = <Message>[...(state.value ?? []), pending];
    state = AsyncValue.data(current);
    try {
      await repo.sendMessage(conversationId, body);
    } catch (_) {
      if (ref.mounted) {
        state = AsyncValue.data(
          current.where((m) => m.id != pending.id).toList(growable: false),
        );
      }
      rethrow;
    }
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
