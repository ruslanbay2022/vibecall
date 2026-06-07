import 'package:flutter/material.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/domain/message_delivery_status.dart';
import 'package:vibecall/features/chat/presentation/widgets/message_status_ticks.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.isFromMe;
    final bgColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fgColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message.body,
                style: TextStyle(color: fgColor),
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              MessageStatusTicks(
                status: messageDeliveryStatus(message),
                color: fgColor,
                readColor: isMe ? Colors.lightBlueAccent : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
