import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/platform/call_tab_coordinator_stub.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/call/presentation/providers/incoming_call_listener.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockCallRepository extends Mock implements CallRepository {
  @override
  String get currentUserId => 'user-a';
}

class MockCallCoordinator extends Mock implements StubCallTabCoordinator {}

class MockSession extends Mock implements Session {}

final _session = MockSession();
final _signedIn = AuthState(AuthChangeEvent.signedIn, _session);
final _signedOut = const AuthState(AuthChangeEvent.signedOut, null);

final _invitation = CallInvitation(
  id: 'inv-1',
  roomName: 'dm_a__b_1000',
  callerId: 'user-b',
  receiverId: 'user-a',
  hasVideo: true,
  state: 'ringing',
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(seconds: 45)),
);

void main() {
  group('IncomingCallListener', () {
    late StreamController<CallInvitation> incomingController;
    late StreamController<AuthState> authController;
    late MockAuthRepository mockAuth;
    late MockCallRepository mockRepo;
    late MockCallCoordinator mockCoord;

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          callRepositoryProvider.overrideWithValue(mockRepo),
          callCoordinatorProvider.overrideWithValue(mockCoord),
        ],
      );
    }

    setUp(() {
      incomingController = StreamController<CallInvitation>.broadcast();
      authController = StreamController<AuthState>.broadcast();
      mockAuth = MockAuthRepository();
      mockRepo = MockCallRepository();
      mockCoord = MockCallCoordinator();

      when(() => mockAuth.authStateChanges)
          .thenAnswer((_) => authController.stream);
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockRepo.incomingCallStream())
          .thenAnswer((_) => incomingController.stream);
      when(() => mockCoord.tryBecomeLeader(any()))
          .thenAnswer((_) async => true);
      when(() => mockCoord.onDismiss).thenAnswer(
        (_) => const Stream.empty(),
      );
    });

    tearDown(() {
      incomingController.close();
      authController.close();
    });

    test('watching listener does not throw', () {
      final container = createContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(incomingCallListenerProvider),
        returnsNormally,
      );
    });

    test('incoming call after sign-in triggers tryBecomeLeader', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(incomingCallListenerProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      authController.add(_signedIn);
      await Future.delayed(const Duration(milliseconds: 50));

      incomingController.add(_invitation);
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockCoord.tryBecomeLeader('inv-1')).called(1);
    });

    test('non-leader coordinator does not notify incoming', () async {
      when(() => mockCoord.tryBecomeLeader(any()))
          .thenAnswer((_) async => false);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(incomingCallListenerProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      authController.add(_signedIn);
      await Future.delayed(const Duration(milliseconds: 50));

      incomingController.add(_invitation);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(callControllerProvider);
      expect(state, isA<CallStateIdle>());
    });

    test('call after sign-out is not triggered', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(incomingCallListenerProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      authController.add(_signedIn);
      await Future.delayed(const Duration(milliseconds: 50));
      authController.add(_signedOut);
      await Future.delayed(const Duration(milliseconds: 50));

      incomingController.add(_invitation);
      await Future.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockCoord.tryBecomeLeader(any()));
    });
  });
}
