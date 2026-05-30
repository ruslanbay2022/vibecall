import 'package:flutter_test/flutter_test.dart';
import 'package:vibecall/features/call/platform/call_tab_coordinator_stub.dart';

/// Pure-function helper replicating the election logic in the web coordinator.
/// Picks the winner among claims by lowest tabId (lexicographic).
/// Returns the winning tabId, or null if no claims.
String? _pickLeader(List<Map<String, dynamic>> claims) {
  if (claims.isEmpty) return null;
  final unique = <String, Map<String, dynamic>>{};
  for (final c in claims) {
    unique[c['tabId'] as String] = c;
  }
  final sorted = unique.values.toList()
    ..sort((a, b) => (a['tabId'] as String).compareTo(b['tabId'] as String));
  return sorted.first['tabId'] as String;
}

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

  group('Election logic (pickLeader)', () {
    test('null when no claims', () {
      expect(_pickLeader([]), isNull);
    });

    test('single claim — winner is self', () {
      final result = _pickLeader([
        {'tabId': 'tab-a', 'ts': '1000'},
      ]);
      expect(result, 'tab-a');
    });

    test('two claims, lower tabId wins', () {
      final result = _pickLeader([
        {'tabId': 'tab-b', 'ts': '2000'},
        {'tabId': 'tab-a', 'ts': '1000'},
      ]);
      expect(result, 'tab-a');
    });

    test('duplicate tabId deduplicated', () {
      final result = _pickLeader([
        {'tabId': 'tab-a', 'ts': '1000'},
        {'tabId': 'tab-a', 'ts': '2000'},
        {'tabId': 'tab-b', 'ts': '1500'},
      ]);
      expect(result, 'tab-a');
    });

    test('lexicographic ordering (not numeric)', () {
      final result = _pickLeader([
        {'tabId': 'tab-2', 'ts': '1000'},
        {'tabId': 'tab-10', 'ts': '2000'},
        {'tabId': 'tab-1', 'ts': '1500'},
      ]);
      // "tab-1" < "tab-10" < "tab-2" lexicographically
      expect(result, 'tab-1');
    });
  });
}
