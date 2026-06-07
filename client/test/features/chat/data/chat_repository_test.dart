// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/data/conversation_dto.dart';
import 'package:vibecall/features/chat/data/message_dto.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> insertCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];
  List<Map<String, dynamic>> selectResponse = const [];

  @override
  PostgrestFilterBuilder<PostgrestList> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    if (values is Map<String, dynamic>) {
      insertCalls.add(values);
    }
    return _FakeFilterBuilder(selectResponse: selectResponse);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> update(Map<dynamic, dynamic> values) {
    updateCalls.add(Map<String, dynamic>.from(values));
    return _FakeFilterBuilder(selectResponse: selectResponse);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeFilterBuilder(selectResponse: selectResponse);
  }
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  final List<Map<String, dynamic>> selectResponse;

  _FakeFilterBuilder({required this.selectResponse});

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> lt(String column, Object value) {
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> or(
    String filters, {
    String? referencedTable,
  }) {
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return _FakeTransformBuilder(selectResponse: selectResponse);
  }

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) {
    return _FakeTransformBuilder(selectResponse: selectResponse);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue([]));
  }
}

class _FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  final List<Map<String, dynamic>> selectResponse;

  _FakeTransformBuilder({required this.selectResponse});

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(selectResponse.cast()));
  }
}

class _FakeRpcBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  final String response;

  _FakeRpcBuilder({required this.response});

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(response));
  }
}

void main() {
  group('MessageDto.fromJson', () {
    test('parses snake_case fields correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'sender_id': 'user-a',
        'body': 'Hello',
        'delivered_at': null,
        'read_at': null,
        'created_at': now.toIso8601String(),
      };

      final dto = MessageDto.fromJson(json);

      expect(dto.id, 'msg-1');
      expect(dto.conversationId, 'conv-1');
      expect(dto.senderId, 'user-a');
      expect(dto.body, 'Hello');
      expect(dto.readAt, isNull);
    });

    test('parses read_at when present', () {
      final now = DateTime.now();
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-1',
        'sender_id': 'user-b',
        'body': 'Hi',
        'delivered_at': null,
        'read_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      };

      final dto = MessageDto.fromJson(json);

      expect(dto.readAt, isNotNull);
    });
  });

  group('ConversationDto.toDomain', () {
    test('resolves peer as user_b when current user is user_a', () {
      final now = DateTime.now();
      final dto = ConversationDto.fromJson({
        'id': 'conv-1',
        'user_a': 'user-a',
        'user_b': 'user-b',
        'last_message_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'peer_a': {
          'username': 'alice',
          'display_name': 'Alice',
          'avatar_url': 'https://example.com/alice.png',
        },
        'peer_b': {
          'username': 'bob',
          'display_name': 'Bob',
          'avatar_url': 'https://example.com/bob.png',
        },
      });

      final conv = dto.toDomain(currentUserId: 'user-a');

      expect(conv.peer.id, 'user-b');
      expect(conv.peer.username, 'bob');
      expect(conv.peer.displayName, 'Bob');
    });

    test('resolves peer as user_a when current user is user_b', () {
      final now = DateTime.now();
      final dto = ConversationDto.fromJson({
        'id': 'conv-2',
        'user_a': 'user-a',
        'user_b': 'user-b',
        'last_message_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'peer_a': {
          'username': 'alice',
          'display_name': null,
          'avatar_url': null,
        },
        'peer_b': {
          'username': 'bob',
          'display_name': null,
          'avatar_url': null,
        },
      });

      final conv = dto.toDomain(currentUserId: 'user-b');

      expect(conv.peer.id, 'user-a');
      expect(conv.peer.username, 'alice');
    });
  });

  group('SupabaseChatRepository', () {
    late MockSupabaseClient mockClient;
    late MockFunctionsClient mockFunctions;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late FakeQueryBuilder fakeQuery;
    late SupabaseChatRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockFunctions = MockFunctionsClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      fakeQuery = FakeQueryBuilder();

      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockClient.functions).thenReturn(mockFunctions);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-a');
      when(() => mockClient.from('messages')).thenAnswer((_) => fakeQuery);
      when(() => mockClient.from('conversations')).thenAnswer((_) => fakeQuery);

      repository = SupabaseChatRepository(client: mockClient);
    });

    group('ensureConversation', () {
      test('calls RPC with p_other param', () async {
        when(() => mockClient.rpc(
              'ensure_conversation',
              params: any(named: 'params'),
            )).thenAnswer((_) => _FakeRpcBuilder(response: 'conv-123'));

        final result = await repository.ensureConversation('user-b');

        expect(result, 'conv-123');
        verify(() => mockClient.rpc(
              'ensure_conversation',
              params: {'p_other': 'user-b'},
            )).called(1);
      });
    });

    group('fetchMessages', () {
      test('returns messages in chronological order', () async {
        final now = DateTime.now();
        fakeQuery.selectResponse = [
          {
            'id': 'msg-2',
            'conversation_id': 'conv-1',
            'sender_id': 'user-b',
            'body': 'Second',
            'read_at': null,
            'created_at': now.add(const Duration(seconds: 1)).toIso8601String(),
          },
          {
            'id': 'msg-1',
            'conversation_id': 'conv-1',
            'sender_id': 'user-a',
            'body': 'First',
            'read_at': null,
            'created_at': now.toIso8601String(),
          },
        ];

        final messages = await repository.fetchMessages('conv-1');

        expect(messages, hasLength(2));
        expect(messages[0].id, 'msg-1');
        expect(messages[1].id, 'msg-2');
        expect(messages[0].isFromMe, isTrue);
        expect(messages[1].isFromMe, isFalse);
      });

      test('applies beforeCursor when provided', () async {
        final cursor = DateTime.now().subtract(const Duration(hours: 1));
        fakeQuery.selectResponse = [];

        await repository.fetchMessages('conv-1', beforeCursor: cursor);

        // Just verify it doesn't throw; the fake builder chains .lt()
        expect(true, isTrue);
      });
    });

    group('sendMessage', () {
      test('inserts message with sender_id = current user', () async {
        await repository.sendMessage('conv-1', 'Hello');

        expect(fakeQuery.insertCalls, [
          {
            'conversation_id': 'conv-1',
            'sender_id': 'user-a',
            'body': 'Hello',
          },
        ]);
      });
    });

    group('markRead', () {
      test('updates read_at timestamp', () async {
        await repository.markRead('msg-1');

        expect(fakeQuery.updateCalls, hasLength(1));
        expect(fakeQuery.updateCalls.first.containsKey('read_at'), isTrue);
      });
    });
  });
}
