// ignore_for_file: must_be_immutable

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/domain/call_outcome.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';

class MockCallRepository extends Mock implements CallRepository {}

void main() {
  group('CallState', () {
    test('initial idle state', () {
      const state = CallStateIdle();
      expect(state, isA<CallStateIdle>());
    });

    test('outgoing state has roomName and receiverId', () {
      const state = CallStateOutgoing(
        roomName: 'dm_a__b_1000',
        receiverId: 'user-b',
      );
      expect(state.roomName, 'dm_a__b_1000');
      expect(state.receiverId, 'user-b');
    });

    test('ended state wraps CallOutcome', () {
      const state = CallStateEnded(outcome: CallOutcome.busy);
      expect(state, isA<CallStateEnded>());
      expect(state.outcome, CallOutcome.busy);
    });

    test('error state has message', () {
      const state = CallStateError(message: 'something went wrong');
      expect(state.message, 'something went wrong');
    });
  });

  group('CallController', () {
    late MockCallRepository mockRepo;

    CallController createController() {
      final container = ProviderContainer(
        overrides: [
          callRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      return container.read(callControllerProvider.notifier);
    }

    setUp(() {
      mockRepo = MockCallRepository();
      when(() => mockRepo.currentUserId).thenReturn('user-a');
    });

    test('initial state is idle', () {
      final controller = createController();
      expect(controller.state, isA<CallStateIdle>());
    });

    test('startCall with busy transitions to ended(busy)', () async {
      when(() => mockRepo.startCall(
            any(),
            hasVideo: any(named: 'hasVideo'),
          )).thenThrow(CallBusyException());

      final controller = createController();
      await controller.startCall(receiverId: 'user-b', video: true);

      expect(controller.state, isA<CallStateEnded>());
      expect(
        (controller.state as CallStateEnded).outcome,
        CallOutcome.busy,
      );
      verify(() => mockRepo.startCall('user-b', hasVideo: true)).called(1);
    });

    test('startCall from non-idle state does nothing', () async {
      when(() => mockRepo.startCall(
            any(),
            hasVideo: any(named: 'hasVideo'),
          )).thenThrow(CallBusyException());

      final controller = createController();

      await controller.startCall(receiverId: 'user-b', video: true);
      final afterFirstCall = controller.state;

      await controller.startCall(receiverId: 'user-c', video: false);

      expect(controller.state, same(afterFirstCall));
      verify(() => mockRepo.startCall('user-b', hasVideo: true)).called(1);
      verifyNever(() => mockRepo.startCall('user-c', hasVideo: false));
    });

    test('cancel transitions to ended(cancelled)', () async {
      final controller = createController();

      await controller.cancel();

      expect(controller.state, isA<CallStateEnded>());
      expect(
        (controller.state as CallStateEnded).outcome,
        CallOutcome.cancelled,
      );
    });

    test('hangup transitions to ended(accepted)', () async {
      final controller = createController();

      await controller.hangup();

      expect(controller.state, isA<CallStateEnded>());
      expect(
        (controller.state as CallStateEnded).outcome,
        CallOutcome.accepted,
      );
    });

    test('reject transitions to ended(rejected)', () async {
      when(() => mockRepo.rejectCall(any())).thenAnswer((_) async {});

      final controller = createController();

      await controller.reject(CallInvitation(
        id: 'inv-1',
        roomName: 'dm_a__b_1000',
        callerId: 'user-c',
        receiverId: 'user-a',
        hasVideo: true,
        state: 'ringing',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(seconds: 45)),
      ));

      expect(controller.state, isA<CallStateEnded>());
      expect(
        (controller.state as CallStateEnded).outcome,
        CallOutcome.rejected,
      );
    });
  });
}
