// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/search/data/search_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  group('SearchUserDto', () {
    test('parses fromJson correctly', () {
      final json = {
        'id': 'user-1',
        'username': 'alice',
        'display_name': 'Alice',
        'avatar_url': 'https://example.com/avatar.jpg',
      };

      final dto = SearchUserDto.fromJson(json);

      expect(dto.id, 'user-1');
      expect(dto.username, 'alice');
      expect(dto.displayName, 'Alice');
      expect(dto.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('handles null displayName and avatarUrl', () {
      final json = {
        'id': 'user-2',
        'username': 'bob',
      };

      final dto = SearchUserDto.fromJson(json);

      expect(dto.id, 'user-2');
      expect(dto.username, 'bob');
      expect(dto.displayName, isNull);
      expect(dto.avatarUrl, isNull);
    });
  });

  group('SupabaseSearchRepository', () {
    late MockSupabaseClient mockClient;
    late SupabaseSearchRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      repository = SupabaseSearchRepository(client: mockClient);
    });

    test('searchUsers calls rpc with correct params and parses result',
        () async {
      final rpcResult = [
        {
          'id': 'user-1',
          'username': 'alice',
          'display_name': 'Alice',
          'avatar_url': null,
        },
      ];

      when(() => mockClient.rpc('search_users', params: {'q': 'ali'}))
          .thenAnswer((_) => _FakeFilterBuilder(result: rpcResult));

      final results = await repository.searchUsers('ali');

      expect(results.length, 1);
      expect(results[0].id, 'user-1');
      expect(results[0].username, 'alice');
    });

    test('searchUsers returns empty list when no results', () async {
      when(() => mockClient.rpc('search_users', params: {'q': 'xyz'}))
          .thenAnswer((_) => _FakeFilterBuilder(result: []));

      final results = await repository.searchUsers('xyz');

      expect(results, isEmpty);
    });
  });
}

class _FakeFilterBuilder extends Fake implements PostgrestFilterBuilder<Object> {
  final List<Map<String, dynamic>> result;

  _FakeFilterBuilder({required this.result});

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Object value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(result));
  }
}
