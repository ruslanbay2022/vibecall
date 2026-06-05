import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_call_listener.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_ringtone.dart';
import 'package:vibecall/features/call/presentation/widgets/incoming_call_overlay.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

class CallAppShell extends ConsumerStatefulWidget {
  final Widget child;

  const CallAppShell({super.key, required this.child});

  @override
  ConsumerState<CallAppShell> createState() => _CallAppShellState();
}

class _CallAppShellState extends ConsumerState<CallAppShell> {
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
  Widget build(BuildContext context) {
    ref.watch(incomingCallListenerProvider);
    ref.watch(incomingRingtoneProvider);

    ref.listen(callControllerProvider, (_, next) {
      final router = GoRouter.of(context);
      final isOnCall = router.state.matchedLocation == '/call';

      if (next is CallStateIncoming) {
        if (isOnCall) router.pop();
      } else if (next is CallStateConnecting ||
          next is CallStateOutgoing ||
          next is CallStateActive ||
          next is CallStateEnded ||
          next is CallStateError) {
        if (!isOnCall) router.push('/call');
      } else if (next is CallStateIdle) {
        if (isOnCall) router.pop();
      }
    });

    return Stack(
      children: [
        widget.child,
        const IncomingCallOverlay(),
      ],
    );
  }
}
