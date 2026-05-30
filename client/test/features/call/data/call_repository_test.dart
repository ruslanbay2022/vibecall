// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_invitation_dto.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/data/call_token.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  PostgrestFilterBuilder<PostgrestList> update(Map<dynamic, dynamic> values) {
    updateCalls.add(Map<String, dynamic>.from(values));
    return _FakeFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeFilterBuilder();
  }
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object? value) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue([]));
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
  });
}
