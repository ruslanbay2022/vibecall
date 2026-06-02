import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';
import 'package:vibecall/features/call/data/call_repository.dart';
import 'package:vibecall/features/call/domain/call_invitation.dart';
import 'package:vibecall/features/call/platform/call_tab_coordinator.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';

part 'incoming_call_listener.g.dart';

@Riverpod(keepAlive: true)
CallTabCoordinator callCoordinator(Ref ref) {
  return createCallTabCoordinator();
}

@Riverpod(keepAlive: true)
class IncomingCallListener extends _$IncomingCallListener {
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<CallInvitation>? _callSub;
  StreamSubscription<String>? _callDismissSub;
  StreamSubscription<String>? _dismissSub;

  @override
  void build() {
    ref.onDispose(() {
      _authSub?.cancel();
      _callSub?.cancel();
      _callDismissSub?.cancel();
      _dismissSub?.cancel();
    });

    _authSub = ref.watch(authRepositoryProvider).authStateChanges.listen((state) {
      if (state.session != null) {
        _subscribeCalls();
      } else {
        _unsubscribeCalls();
      }
    });

    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user != null) {
      Future.microtask(_subscribeCalls);
    }
  }

  void _subscribeCalls() {
    _callSub?.cancel();
    _callDismissSub?.cancel();
    _dismissSub?.cancel();

    final coordinator = ref.read(callCoordinatorProvider);
    _dismissSub = coordinator.onDismiss.listen((invitationId) {
      _dismissIncomingIfMatching(invitationId);
    });

    final repo = ref.read(callRepositoryProvider);
    _callSub = repo.incomingCallStream().listen(
      (invitation) => _onIncomingCall(invitation, coordinator),
    );
    _callDismissSub = repo.incomingCallDismissStream().listen(
      _dismissIncomingIfMatching,
    );
  }

  void _dismissIncomingIfMatching(String invitationId) {
    final state = ref.read(callControllerProvider);
    if (state is CallStateIncoming && state.invitation.id == invitationId) {
      ref.read(callControllerProvider.notifier).clearIncoming();
    }
  }

  Future<void> _onIncomingCall(
    CallInvitation invitation,
    CallTabCoordinator coordinator,
  ) async {
    if (!await coordinator.tryBecomeLeader(invitation.id)) return;
    ref.read(callControllerProvider.notifier).notifyIncoming(invitation);
  }

  void _unsubscribeCalls() {
    _callSub?.cancel();
    _callSub = null;
    _callDismissSub?.cancel();
    _callDismissSub = null;
    _dismissSub?.cancel();
    _dismissSub = null;
  }
}
