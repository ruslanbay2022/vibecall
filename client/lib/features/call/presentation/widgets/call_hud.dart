import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class CallHud extends ConsumerWidget {
  final CallStateActive state;

  const CallHud({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(callControllerProvider.notifier);
    final room = state.room;
    final local = room.localParticipant;
    final isMuted = local?.isMicrophoneEnabled() ?? true;
    final isCameraOn = local?.isCameraEnabled() ?? true;

    return Container(
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
            if (state.hasVideo)
              _IconLabel(
                icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
                label: isCameraOn ? l10n.callCameraOff : l10n.callCameraOn,
                onPressed: () => notifier.toggleCamera(),
              ),
            if (state.hasVideo)
              _IconLabel(
                icon: Icons.flip_camera_ios,
                label: l10n.callSwitchCamera,
                onPressed: () => notifier.switchCamera(),
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
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final double iconSize;
  final bool enabled;
  final VoidCallback onPressed;

  const _IconLabel({
    required this.icon,
    required this.label,
    this.color,
    this.iconSize = 28,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: iconSize),
          color: color ?? Colors.white,
          onPressed: enabled ? onPressed : null,
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}
