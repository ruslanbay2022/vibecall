import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/domain/message_delivery_status.dart';

Message _msg({
  bool isPending = false,
  DateTime? deliveredAt,
  DateTime? readAt,
}) {
  return Message(
    id: 'msg-1',
    conversationId: 'conv-1',
    senderId: 'me',
    body: 'hi',
    deliveredAt: deliveredAt,
    readAt: readAt,
    createdAt: DateTime(2024, 1, 1),
    isFromMe: true,
    isPending: isPending,
  );
}

void main() {
  group('messageDeliveryStatus', () {
    test('returns sending for pending message', () {
      expect(
        messageDeliveryStatus(_msg(isPending: true)),
        MessageDeliveryStatus.sending,
      );
    });

    test('returns sent when persisted but not delivered', () {
      expect(
        messageDeliveryStatus(_msg()),
        MessageDeliveryStatus.sent,
      );
    });

    test('returns delivered when delivered_at is set', () {
      expect(
        messageDeliveryStatus(_msg(deliveredAt: DateTime(2024, 1, 2))),
        MessageDeliveryStatus.delivered,
      );
    });

    test('returns read when read_at is set', () {
      expect(
        messageDeliveryStatus(
          _msg(
            deliveredAt: DateTime(2024, 1, 2),
            readAt: DateTime(2024, 1, 3),
          ),
        ),
        MessageDeliveryStatus.read,
      );
    });
  });
}
