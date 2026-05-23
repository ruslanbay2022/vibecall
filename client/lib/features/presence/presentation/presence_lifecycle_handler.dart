import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/presence/presentation/providers/presence_controller.dart';

class PresenceLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const PresenceLifecycleHandler({super.key, required this.child});

  @override
  ConsumerState<PresenceLifecycleHandler> createState() =>
      _PresenceLifecycleHandlerState();
}

class _PresenceLifecycleHandlerState
    extends ConsumerState<PresenceLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(presenceControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.untrack();
    } else if (state == AppLifecycleState.resumed) {
      controller.track();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
