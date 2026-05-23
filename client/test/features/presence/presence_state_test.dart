import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:vibecall/features/presence/presentation/providers/presence_controller.dart';

SinglePresenceState _state(String key) {
  return SinglePresenceState(key: key, presences: []);
}

void main() {
  group('onlineUserIdsFromPresenceState', () {
    test('returns empty set for empty list', () {
      final result = onlineUserIdsFromPresenceState([]);
      expect(result, isEmpty);
    });

    test('returns single user id', () {
      final result = onlineUserIdsFromPresenceState([_state('user-a')]);
      expect(result, {'user-a'});
    });

    test('returns multiple user ids', () {
      final result = onlineUserIdsFromPresenceState([
        _state('user-a'),
        _state('user-b'),
        _state('user-c'),
      ]);
      expect(result, {'user-a', 'user-b', 'user-c'});
    });

    test('deduplicates duplicate keys', () {
      final result = onlineUserIdsFromPresenceState([
        _state('user-a'),
        _state('user-a'),
        _state('user-b'),
      ]);
      expect(result, {'user-a', 'user-b'});
    });
  });
}
