import 'package:flutter/material.dart';
import 'package:vibecall/features/chat/domain/message_delivery_status.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class MessageStatusTicks extends StatelessWidget {
  final MessageDeliveryStatus status;
  final Color? color;
  final Color? readColor;

  const MessageStatusTicks({
    super.key,
    required this.status,
    this.color,
    this.readColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaultColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final readTickColor = readColor ?? Colors.lightBlueAccent;

    final (IconData icon, Color iconColor, String semantics) = switch (status) {
      MessageDeliveryStatus.sending => (
          Icons.schedule,
          defaultColor.withValues(alpha: 0.75),
          l10n.chatMessageStatusSending,
        ),
      MessageDeliveryStatus.sent => (
          Icons.done,
          defaultColor.withValues(alpha: 0.85),
          l10n.chatMessageStatusSent,
        ),
      MessageDeliveryStatus.delivered => (
          Icons.done_all,
          defaultColor.withValues(alpha: 0.85),
          l10n.chatMessageStatusDelivered,
        ),
      MessageDeliveryStatus.read => (
          Icons.done_all,
          readTickColor,
          l10n.chatMessageStatusRead,
        ),
    };

    return Semantics(
      label: semantics,
      child: Icon(icon, size: 16, color: iconColor),
    );
  }
}
