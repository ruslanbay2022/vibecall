import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_call_listener.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_ringtone.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class IncomingCallOverlay extends ConsumerWidget {
  const IncomingCallOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    if (callState is! CallStateIncoming) return const SizedBox.shrink();

    final inv = callState.invitation;
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        ModalBarrier(dismissible: false, color: Colors.black.withValues(alpha: 0.4)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.incomingCallTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        inv.hasVideo ? Icons.videocam : Icons.phone,
                        size: 48,
                        color: inv.hasVideo ? Colors.blue : Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inv.hasVideo
                            ? l10n.incomingCallVideo
                            : l10n.incomingCallAudio,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.incomingCallFrom(inv.callerId),
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _reject(context, ref, inv),
                            icon: const Icon(Icons.call_end),
                            label: Text(l10n.rejectCall),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _accept(context, ref, inv),
                            icon: const Icon(Icons.call),
                            label: Text(l10n.acceptCall),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _accept(BuildContext context, WidgetRef ref, CallInvitation inv) {
    unawaited(ref.read(incomingRingtoneProvider.notifier).unlockForNextRing());
    ref.read(callControllerProvider.notifier).accept(inv);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, CallInvitation inv) async {
    unawaited(ref.read(incomingRingtoneProvider.notifier).unlockForNextRing());
    final repo = ref.read(callRepositoryProvider);
    try {
      await repo.rejectCall(inv.id);
    } catch (_) {}
    ref.read(callControllerProvider.notifier).clearIncoming();
    ref.read(callCoordinatorProvider).postDismiss(inv.id);
  }
}
