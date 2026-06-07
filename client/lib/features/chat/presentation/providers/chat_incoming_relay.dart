import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

part 'chat_incoming_relay.g.dart';

/// Single Realtime subscription shared by sound + unread badge logic.
@Riverpod(keepAlive: true)
class ChatIncomingRelay extends _$ChatIncomingRelay {
  StreamSubscription<Message>? _subscription;
  StreamSubscription<AuthState>? _authSub;

  @override
  void build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _authSub?.cancel();
      _subscription = null;
      _authSub = null;
    });

    final authRepo = ref.watch(authRepositoryProvider);
    _authSub = authRepo.authStateChanges.listen((authState) {
      if (authState.session != null) {
        _subscribe();
      } else {
        _unsubscribe();
      }
    });

    if (authRepo.currentUser != null) {
      Future.microtask(_subscribe);
    }
  }

  void _subscribe() {
    if (ref.read(authRepositoryProvider).currentUser == null) return;

    _subscription?.cancel();
    final repo = ref.read(chatRepositoryProvider);
    _subscription = repo.globalIncomingMessageStream().listen(
      (message) {
        if (!message.isFromMe && message.deliveredAt == null) {
          unawaited(repo.markDelivered(message.id));
        }
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

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
