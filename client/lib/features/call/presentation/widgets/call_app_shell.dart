import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_call_listener.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_ringtone.dart';
import 'package:vibecall/features/call/presentation/widgets/incoming_call_overlay.dart';
import 'package:vibecall/features/chat/presentation/widgets/active_chat_route_sync.dart';

class CallAppShell extends ConsumerWidget {
  final Widget child;

  const CallAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        const ActiveChatRouteSync(),
        child,
        const IncomingCallOverlay(),
      ],
    );
  }
}
