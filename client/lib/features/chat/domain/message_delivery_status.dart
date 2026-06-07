import 'package:vibecall/features/chat/domain/message.dart';

enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  read,
}

MessageDeliveryStatus messageDeliveryStatus(Message message) {
  if (message.isPending) return MessageDeliveryStatus.sending;
  if (message.readAt != null) return MessageDeliveryStatus.read;
  if (message.deliveredAt != null) return MessageDeliveryStatus.delivered;
  return MessageDeliveryStatus.sent;
}
