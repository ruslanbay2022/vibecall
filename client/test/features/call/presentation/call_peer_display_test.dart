import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/call/presentation/widgets/call_peer_display.dart';

void main() {
  group('formatCallPeerLabel', () {
    test('prefers @username', () {
      expect(
        formatCallPeerLabel(
          userId: 'uuid',
          username: 'alice',
          displayName: 'Alice',
        ),
        '@alice',
      );
    });

    test('falls back to display name', () {
      expect(
        formatCallPeerLabel(
          userId: 'uuid',
          displayName: 'Alice',
        ),
        'Alice',
      );
    });

    test('falls back to user id', () {
      expect(
        formatCallPeerLabel(userId: 'uuid-123'),
        'uuid-123',
      );
    });
  });
}
