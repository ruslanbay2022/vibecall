import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/call/platform/call_tab_coordinator_stub.dart';

void main() {
  group('StubCallTabCoordinator', () {
    late StubCallTabCoordinator coordinator;

    setUp(() {
      coordinator = StubCallTabCoordinator();
    });

    test('isLeader is always true', () {
      expect(coordinator.isLeader, isTrue);
    });

    test('tryBecomeLeader always returns true', () async {
      final result = await coordinator.tryBecomeLeader('inv-1');
      expect(result, isTrue);
    });

    test('postDismiss does not throw', () {
      expect(() => coordinator.postDismiss('inv-1'), returnsNormally);
    });

    test('onDismiss stream is empty', () {
      expect(coordinator.onDismiss, emitsDone);
    });

    test('dispose does not throw', () {
      expect(() => coordinator.dispose(), returnsNormally);
    });
  });

  group('createCallTabCoordinator', () {
    test('returns StubCallTabCoordinator', () {
      final coord = createCallTabCoordinator();
      expect(coord, isA<StubCallTabCoordinator>());
    });
  });
}
