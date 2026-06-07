import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/widgets/call_media_utils.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';
import 'package:vibecall/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:vibecall/l10n/app_localizations.dart';

/// Vertical space to reserve above [CallHud] so in-call chat input stays tappable.
double callHudReservedHeight(BuildContext context) {
  final safeBottom = MediaQuery.paddingOf(context).bottom;
  // Icon (~48) + label (~12) + vertical padding (32) + margin.
  return safeBottom + 88;
}

class CallHud extends ConsumerWidget {
  final CallStateActive state;
  final bool chatOpen;
  final String? conversationId;
  final VoidCallback? onToggleChat;

  const CallHud({
    super.key,
    required this.state,
    this.chatOpen = false,
    this.conversationId,
    this.onToggleChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final active = callState is CallStateActive ? callState : state;
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(callControllerProvider.notifier);
    final local = active.room.localParticipant;
    final isMuted = !(local?.isMicrophoneEnabled() ?? false);
    final isCameraOn = isParticipantCameraOn(local);
    final unreadCounts = ref.watch(unreadCountsControllerProvider).value ?? {};
    final chatUnreadCount = chatOpen || conversationId == null
        ? 0
        : unreadCounts[conversationId] ?? 0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        unawaited(
          ref.read(chatMessageSoundProvider.notifier).unlockForNextSound(),
        );
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IconLabel(
              icon: isMuted ? Icons.mic_off : Icons.mic,
              label: isMuted ? l10n.callUnmute : l10n.callMute,
              onPressed: () => notifier.toggleMute(),
            ),
            if (active.hasVideo)
              _IconLabel(
                icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
                label: isCameraOn ? l10n.callCameraOff : l10n.callCameraOn,
                onPressed: () async {
                  final ok = await notifier.toggleCamera();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.callCameraEnableFailed)),
                    );
                  }
                },
              ),
            if (active.hasVideo)
              _IconLabel(
                icon: Icons.flip_camera_ios,
                label: l10n.callSwitchCamera,
                enabled: isCameraOn,
                onPressed: () => notifier.switchCamera(),
              ),
            _IconLabel(
              icon: chatOpen ? Icons.chat : Icons.chat_bubble_outline,
              label: l10n.callOpenChat,
              onPressed: () {
                unawaited(
                  ref
                      .read(chatMessageSoundProvider.notifier)
                      .unlockForNextSound(),
                );
                (onToggleChat ?? () {})();
              },
              enabled: onToggleChat != null,
              badgeCount: chatUnreadCount,
            ),
            _IconLabel(
              icon: Icons.call_end,
              label: l10n.callEndButton,
              color: Colors.red,
              iconSize: 36,
              onPressed: () => notifier.hangup(),
            ),
            _IconLabel(
              icon: Icons.screen_share,
              label: l10n.callScreenShareStub,
              enabled: false,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.callScreenShareStub)),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final double iconSize;
  final bool enabled;
  final int badgeCount;
  final VoidCallback onPressed;

  const _IconLabel({
    required this.icon,
    required this.label,
    this.color,
    this.iconSize = 28,
    this.enabled = true,
    this.badgeCount = 0,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconButton = IconButton(
      icon: Icon(icon, size: iconSize),
      color: color ?? Colors.white,
      onPressed: enabled ? onPressed : null,
    );
    if (badgeCount > 0) {
      iconButton = ChatUnreadBadge(count: badgeCount, child: iconButton);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconButton,
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
