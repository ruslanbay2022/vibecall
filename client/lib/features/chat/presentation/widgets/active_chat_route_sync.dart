import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

/// Keeps [activeChatConversationProvider] in sync with the current route.
class ActiveChatRouteSync extends ConsumerStatefulWidget {
  const ActiveChatRouteSync({super.key});

  @override
  ConsumerState<ActiveChatRouteSync> createState() =>
      _ActiveChatRouteSyncState();
}

class _ActiveChatRouteSyncState extends ConsumerState<ActiveChatRouteSync> {
  String? _syncedActiveChatId;
  VoidCallback? _routeListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    _routeListener ??= () => _syncActiveChatFromRoute(router);
    router.routerDelegate.removeListener(_routeListener!);
    router.routerDelegate.addListener(_routeListener!);
    _syncActiveChatFromRoute(router);
  }

  void _syncActiveChatFromRoute(GoRouter router) {
    final location = router.state.matchedLocation;
    final chatId = location.startsWith('/chat/')
        ? router.state.pathParameters['conversationId']
        : null;

    if (_syncedActiveChatId == chatId) return;
    final previousChatId = _syncedActiveChatId;
    _syncedActiveChatId = chatId;

    Future.microtask(() {
      if (!mounted) return;
      ref.read(activeChatConversationProvider.notifier).set(chatId);
      if (chatId != null) {
        ref
            .read(unreadCountsControllerProvider.notifier)
            .clearForConversation(chatId);
      } else if (previousChatId != null) {
        unawaited(ref.read(unreadCountsControllerProvider.notifier).refresh());
      }
    });
  }

  @override
  void dispose() {
    if (_routeListener != null) {
      GoRouter.of(context).routerDelegate.removeListener(_routeListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
