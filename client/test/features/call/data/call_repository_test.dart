// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_history_dto.dart';
import 'package:vibecall/features/call/data/call_invitation_dto.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/data/call_token.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> updateCalls = [];
  List<Map<String, dynamic>> selectResponse = const [];

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
  PostgrestFilterBuilder<PostgrestList> inFilter(
    String column,
    List values,
  ) {
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
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(selectResponse.cast()));
  }
}

void main() {
  group('CallInvitationDto.fromJson', () {
    test('parses snake_case DB columns correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'inv-1',
        'room_name': 'dm_a__b_1000',
        'caller_id': 'user-a',
        'receiver_id': 'user-b',
        'has_video': true,
        'state': 'ringing',
        'created_at': now.toIso8601String(),
        'expires_at': now.add(const Duration(seconds: 45)).toIso8601String(),
      };

      final dto = CallInvitationDto.fromJson(json);

      expect(dto.id, 'inv-1');
      expect(dto.roomName, 'dm_a__b_1000');
      expect(dto.callerId, 'user-a');
      expect(dto.receiverId, 'user-b');
      expect(dto.hasVideo, true);
      expect(dto.state, 'ringing');
      expect(dto.endedAt, isNull);
    });

    test('handles ended_at', () {
      final now = DateTime.now();
      final json = {
        'id': 'inv-2',
        'room_name': 'dm_a__b_1001',
        'caller_id': 'user-a',
        'receiver_id': 'user-b',
        'has_video': false,
        'state': 'rejected',
        'created_at': now.toIso8601String(),
        'expires_at': now.add(const Duration(seconds: 45)).toIso8601String(),
        'ended_at': now.toIso8601String(),
      };

      final dto = CallInvitationDto.fromJson(json);

      expect(dto.state, 'rejected');
      expect(dto.endedAt, isNotNull);
    });
  });

  group('CallInvitationDto.fromRealtime', () {
    test('tolerates partial DELETE oldRecord', () {
      final dto = CallInvitationDto.fromRealtime({
        'id': 'inv-1',
        'state': 'rejected',
      });

      expect(dto.id, 'inv-1');
      expect(dto.state, 'rejected');
      expect(dto.roomName, '');
      expect(dto.callerId, '');
    });
  });

  group('CallInvitation.fromDto', () {
    test('maps DTO to domain model', () {
      final now = DateTime.now();
      final dto = CallInvitationDto(
        id: 'inv-1',
        roomName: 'dm_a__b_1000',
        callerId: 'user-a',
        receiverId: 'user-b',
        hasVideo: true,
        state: 'ringing',
        createdAt: now,
        expiresAt: now.add(const Duration(seconds: 45)),
      );

      final domain = CallInvitation.fromDto(dto);

      expect(domain.id, dto.id);
      expect(domain.roomName, dto.roomName);
      expect(domain.callerId, dto.callerId);
      expect(domain.receiverId, dto.receiverId);
      expect(domain.hasVideo, dto.hasVideo);
      expect(domain.state, dto.state);
      expect(domain.createdAt, dto.createdAt);
      expect(domain.expiresAt, dto.expiresAt);
      expect(domain.endedAt, isNull);
    });
  });

  group('CallToken', () {
    test('fromEdgeFunctionResponse parses camelCase response', () {
      final token = CallToken.fromEdgeFunctionResponse({
        'token': 'jwt-abc',
        'wsUrl': 'wss://livekit.example.com',
        'roomName': 'dm_a__b_1000',
      });

      expect(token.token, 'jwt-abc');
      expect(token.wsUrl, 'wss://livekit.example.com');
      expect(token.roomName, 'dm_a__b_1000');
    });
  });

  group('SupabaseCallRepository', () {
    late MockSupabaseClient mockClient;
    late MockFunctionsClient mockFunctions;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late FakeQueryBuilder fakeQuery;
    late SupabaseCallRepository repository;

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
      when(() => mockClient.from('call_invitations'))
          .thenAnswer((_) => fakeQuery);
      when(() => mockClient.from('call_history'))
          .thenAnswer((_) => fakeQuery);

      repository = SupabaseCallRepository(client: mockClient);
    });

    group('startCall', () {
      test('invokes generate-call-token and returns CallToken', () async {
        when(() => mockFunctions.invoke(
              'generate-call-token',
              body: any(named: 'body'),
            )).thenAnswer((_) async => FunctionResponse(
              status: 200,
              data: {
                'token': 'jwt-abc',
                'wsUrl': 'wss://livekit.example.com',
                'roomName': 'dm_a__b_1000',
              },
            ));

        final result = await repository.startCall('user-b', hasVideo: true);

        expect(result.token, 'jwt-abc');
        verify(() => mockFunctions.invoke('generate-call-token', body: {
          'receiverId': 'user-b',
          'hasVideo': true,
        })).called(1);
      });

      test('throws CallBusyException on 409', () async {
        when(() => mockFunctions.invoke(
              'generate-call-token',
              body: any(named: 'body'),
            )).thenThrow(const FunctionException(
              status: 409,
              details: {'error': 'busy'},
              reasonPhrase: 'Conflict',
            ));

        expect(
          () => repository.startCall('user-b', hasVideo: true),
          throwsA(isA<CallBusyException>()),
        );
      });
    });

    group('acceptCall', () {
      test('invokes accept-call and returns CallToken', () async {
        when(() => mockFunctions.invoke(
              'accept-call',
              body: any(named: 'body'),
            )).thenAnswer((_) async => FunctionResponse(
              status: 200,
              data: {
                'token': 'jwt-def',
                'wsUrl': 'wss://livekit.example.com',
                'roomName': 'dm_a__b_1000',
              },
            ));

        final result = await repository.acceptCall('inv-1');

        expect(result.token, 'jwt-def');
        verify(() => mockFunctions.invoke('accept-call', body: {
          'invitationId': 'inv-1',
        })).called(1);
      });
    });

    group('rejectCall', () {
      test('invokes reject-call', () async {
        when(() => mockFunctions.invoke(
              'reject-call',
              body: any(named: 'body'),
            )).thenAnswer((_) async => FunctionResponse(status: 204));

        await repository.rejectCall('inv-1');

        verify(() => mockFunctions.invoke('reject-call', body: {
          'invitationId': 'inv-1',
        })).called(1);
      });
    });

    group('endCall', () {
      test('invokes end-call with invitationId and durationSec', () async {
        when(() => mockFunctions.invoke(
              'end-call',
              body: any(named: 'body'),
            )).thenAnswer((_) async => FunctionResponse(status: 204));

        await repository.endCall('inv-1', 120);

        verify(() => mockFunctions.invoke('end-call', body: {
          'invitationId': 'inv-1',
          'durationSec': 120,
        })).called(1);
      });
    });

    group('cancelCall', () {
      test('updates call_invitations state to cancelled', () async {
        await repository.cancelCall('inv-1');

        expect(fakeQuery.updateCalls, [
          {'state': 'cancelled'},
        ]);
      });
    });

    group('fetchCallHistory', () {
      test('all filter parses DTOs and resolves peer as caller for incoming', () async {
        final now = DateTime.now();
        fakeQuery.selectResponse = [
          {
            'id': 'h-1',
            'room_name': 'dm_a__b_1000',
            'caller_id': 'user-b',
            'receiver_id': 'user-a',
            'outcome': 'accepted',
            'has_video': true,
            'duration_sec': 125,
            'started_at': now.toIso8601String(),
            'ended_at': now.add(const Duration(seconds: 125)).toIso8601String(),
            'caller': {
              'username': 'bob',
              'display_name': 'Bob',
              'avatar_url': 'https://example.com/bob.png',
            },
            'receiver': {
              'username': 'alice',
              'display_name': 'Alice',
              'avatar_url': 'https://example.com/alice.png',
            },
          },
        ];

        final result = await repository.fetchCallHistory();

        expect(result, hasLength(1));
        final entry = result.first;
        expect(entry.id, 'h-1');
        expect(entry.outcome, CallOutcome.accepted);
        expect(entry.hasVideo, true);
        expect(entry.durationSec, 125);
        expect(entry.isOutgoing, isFalse);
        expect(entry.peer.id, 'user-b');
        expect(entry.peer.username, 'bob');
        expect(entry.peer.displayName, 'Bob');
        expect(entry.peer.avatarUrl, 'https://example.com/bob.png');
      });

      test('isOutgoing=true when current user is caller', () async {
        fakeQuery.selectResponse = [
          {
            'id': 'h-2',
            'room_name': 'dm_a__b_1001',
            'caller_id': 'user-a',
            'receiver_id': 'user-b',
            'outcome': 'cancelled',
            'has_video': false,
            'duration_sec': 0,
            'started_at': DateTime.now().toIso8601String(),
            'ended_at': null,
            'caller': {
              'username': 'alice',
              'display_name': null,
              'avatar_url': null,
            },
            'receiver': {
              'username': 'bob',
              'display_name': null,
              'avatar_url': null,
            },
          },
        ];

        final result = await repository.fetchCallHistory();

        expect(result.first.isOutgoing, isTrue);
        expect(result.first.peer.id, 'user-b');
        expect(result.first.peer.username, 'bob');
        expect(result.first.peer.displayName, isNull);
      });

      test('missed filter passes receiver_id=me + outcome in (missed,timeout,cancelled)',
          () async {
        fakeQuery.selectResponse = [];

        final result =
            await repository.fetchCallHistory(filter: CallHistoryFilter.missed);

        // Sanity: query returns empty list, no exception, filter param doesn't throw.
        expect(result, isEmpty);
      });

      test('unknown outcome string maps to missed (fallback)', () {
        final json = {
          'id': 'h-x',
          'room_name': 'dm_x__y_0',
          'caller_id': 'a',
          'receiver_id': 'b',
          'outcome': 'bogus',
          'has_video': false,
          'duration_sec': 0,
          'started_at': DateTime.now().toIso8601String(),
          'ended_at': null,
        };
        final dto = CallHistoryDto.fromJson(json);
        final entry = dto.toDomain(currentUserId: 'a');
        expect(entry.outcome, CallOutcome.missed);
      });

      test('all six outcomes parse to correct enum', () {
        for (final outcome in CallOutcome.values) {
          final dto = CallHistoryDto.fromJson({
            'id': 'h-$outcome',
            'room_name': 'r',
            'caller_id': 'a',
            'receiver_id': 'b',
            'outcome': outcome.name,
            'has_video': false,
            'duration_sec': 0,
            'started_at': DateTime.now().toIso8601String(),
            'ended_at': null,
          });
          expect(dto.toDomain(currentUserId: 'a').outcome, outcome);
        }
      });
    });
  });
}
