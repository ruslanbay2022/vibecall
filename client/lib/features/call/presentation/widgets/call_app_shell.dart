import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_call_listener.dart';
import 'package:vibecall/features/call/presentation/widgets/incoming_call_overlay.dart';

class CallAppShell extends ConsumerWidget {
  final Widget child;

  const CallAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(incomingCallListenerProvider);

    return Stack(
      children: [
        child,
        const IncomingCallOverlay(),
      ],
    );
  }
}
