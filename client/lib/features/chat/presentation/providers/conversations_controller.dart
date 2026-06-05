import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/conversation.dart';

part 'conversations_controller.g.dart';

@riverpod
class ConversationsController extends _$ConversationsController {
  StreamSubscription<List<Conversation>>? _sub;

  @override
  Future<List<Conversation>> build() async {
    final repo = ref.watch(chatRepositoryProvider);

    _sub?.cancel();
    _sub = repo.conversationsStream().listen(
      (conversations) {
        state = AsyncValue.data(conversations);
      },
      onError: (Object e, StackTrace st) {
        state = AsyncValue.error(e, st);
      },
    );

    ref.onDispose(() {
      _sub?.cancel();
    });

    return repo.fetchConversations();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
