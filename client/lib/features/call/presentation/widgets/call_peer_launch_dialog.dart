import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/domain/call_history_entry.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/providers/outgoing_ringtone.dart';
import 'package:vibecall/l10n/app_localizations.dart';

/// Display label for call confirmation (prefers @username).
String callPeerDisplayName(CallHistoryEntry entry) {
  final username = entry.peer.username;
  if (username != null && username.isNotEmpty) {
    return '@$username';
  }
  final name = entry.displayName;
  if (name.isNotEmpty) return name;
  return entry.peer.id;
}

bool canStartCallFromHistory(CallState callState) {
  return callState is! CallStateConnecting &&
      callState is! CallStateOutgoing &&
      callState is! CallStateActive;
}

Future<void> showCallPeerLaunchDialog({
  required BuildContext context,
  required WidgetRef ref,
  required CallHistoryEntry entry,
}) async {
  final l10n = AppLocalizations.of(context);
  final callState = ref.read(callControllerProvider);
  if (!canStartCallFromHistory(callState)) return;

  final peerName = callPeerDisplayName(entry);
  final receiverId = entry.peer.id;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        content: Text(l10n.callHistoryCallPrompt(peerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.callHistoryCallCancel),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            tooltip: l10n.callAudioButton,
            onPressed: () {
              Navigator.pop(dialogContext);
              unawaited(ref
                  .read(outgoingRingtoneProvider.notifier)
                  .unlockForNextRing());
              ref.read(callControllerProvider.notifier).startCall(
                    receiverId: receiverId,
                    video: false,
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.blue),
            tooltip: l10n.callVideoButton,
            onPressed: () {
              Navigator.pop(dialogContext);
              unawaited(ref
                  .read(outgoingRingtoneProvider.notifier)
                  .unlockForNextRing());
              ref.read(callControllerProvider.notifier).startCall(
                    receiverId: receiverId,
                    video: true,
                  );
            },
          ),
        ],
      );
    },
  );
}
