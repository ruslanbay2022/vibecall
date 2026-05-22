// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

/// A simplified fake SupabaseQueryBuilder that records calls for verification.
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> insertCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];
  int deleteCallCount = 0;

  /// If non-null, maybeSingle will resolve with this value.
  Map<String, dynamic>? existingRow;

  @override
  PostgrestFilterBuilder<PostgrestList> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    insertCalls.add(Map<String, dynamic>.from(values as Map));
    return _FakeFilterBuilder(existingRow: existingRow);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> update(Map values) {
    updateCalls.add(Map<String, dynamic>.from(values));
    return _FakeFilterBuilder(existingRow: existingRow);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> delete() {
    deleteCallCount++;
    return _FakeFilterBuilder(existingRow: existingRow);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeFilterBuilder(existingRow: existingRow);
  }
}

/// A fake filter builder that supports eq, maybeSingle, and is awaitable.
class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final Map<String, dynamic>? existingRow;

  _FakeFilterBuilder({this.existingRow});

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object? value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return _FakeTransformBuilder(result: existingRow);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue([]));
  }
}

/// A fake transform builder that is awaitable and returns a configured result.
class _FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  final Map<String, dynamic>? result;

  _FakeTransformBuilder({this.result});

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(result));
  }
}

void main() {
  group('ContactDto.fromJson', () {
    test('parses profile data correctly', () {
      final json = {
        'id': 'contact-id-1',
        'user_id': 'user-a',
        'contact_id': 'user-b',
        'status': 'accepted',
        'profiles': {
          'username': 'alice',
          'display_name': 'Alice Smith',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final dto = ContactDto.fromJson(json);

      expect(dto.id, 'contact-id-1');
      expect(dto.userId, 'user-a');
      expect(dto.contactId, 'user-b');
      expect(dto.status, 'accepted');
      expect(dto.username, 'alice');
      expect(dto.displayName, 'Alice Smith');
      expect(dto.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('handles null profile', () {
      final json = {
        'id': 'contact-id-2',
        'user_id': 'user-a',
        'contact_id': 'user-b',
        'status': 'pending',
      };

      final dto = ContactDto.fromJson(json);

      expect(dto.id, 'contact-id-2');
      expect(dto.status, 'pending');
      expect(dto.username, isNull);
      expect(dto.displayName, isNull);
      expect(dto.avatarUrl, isNull);
    });
  });

  group('SupabaseContactsRepository', () {
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late FakeQueryBuilder fakeQuery;
    late SupabaseContactsRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      fakeQuery = FakeQueryBuilder();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-a');
      when(() => mockClient.from('contacts'))
          .thenAnswer((_) => fakeQuery);

      repository = SupabaseContactsRepository(client: mockClient);
    });

    group('sendRequest', () {
      test('inserts pending contact row', () async {
        await repository.sendRequest('user-b');

        expect(fakeQuery.insertCalls, [
          {'user_id': 'user-a', 'contact_id': 'user-b', 'status': 'pending'},
        ]);
      });
    });

    group('acceptRequest', () {
      test('updates request status and inserts reverse accepted row',
          () async {
        await repository.acceptRequest('contact-id-1', 'user-b');

        expect(fakeQuery.updateCalls, [
          {'status': 'accepted'},
        ]);
        expect(fakeQuery.insertCalls, [
          {
            'user_id': 'user-a',
            'contact_id': 'user-b',
            'status': 'accepted',
          },
        ]);
      });

      test('skips insert when reverse row already exists', () async {
        fakeQuery.existingRow = {'id': 'existing-id'};

        await repository.acceptRequest('contact-id-1', 'user-b');

        expect(fakeQuery.updateCalls, [
          {'status': 'accepted'},
        ]);
        expect(fakeQuery.insertCalls, isEmpty);
      });
    });

    group('remove', () {
      test('deletes both accepted rows (A→B and B→A)', () async {
        await repository.remove('contact-id-1', 'user-b');

        expect(fakeQuery.deleteCallCount, 2);
      });
    });
  });
}
