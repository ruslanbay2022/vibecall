import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

part 'chat_incoming_relay.g.dart';

/// Single Realtime subscription shared by sound + unread badge logic.
@Riverpod(keepAlive: true)
class ChatIncomingRelay extends _$ChatIncomingRelay {
  StreamSubscription<Message>? _subscription;

  @override
  void build() {
    ref.watch(chatRepositoryProvider);

    if (_subscription == null) {
      final repo = ref.read(chatRepositoryProvider);
      _subscription = repo.globalIncomingMessageStream().listen(
        (message) {
          ref.read(chatMessageSoundProvider.notifier).onIncomingMessage(message);
          ref
              .read(unreadCountsControllerProvider.notifier)
              .onIncomingMessage(message);
        },
        onError: (error, stackTrace) {
          debugPrint('chat incoming relay error: $error\n$stackTrace');
        },
      );
    }

    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
  }
}
