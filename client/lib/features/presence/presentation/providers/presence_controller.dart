import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';

part 'presence_controller.g.dart';

Set<String> onlineUserIdsFromPresenceState(
    List<SinglePresenceState> states) {
  return states.map((s) => s.key).toSet();
}

@Riverpod(keepAlive: true)
class PresenceController extends _$PresenceController {
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;

  @override
  Set<String> build() {
    ref.onDispose(() {
      _authSub?.cancel();
      _channel?.untrack();
      _channel?.unsubscribe();
    });

    _authSub = ref.watch(authRepositoryProvider).authStateChanges.listen((state) {
      if (state.session != null) {
        _connect(state.session!.user.id);
      } else {
        _disconnect();
      }
    });

    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user != null) {
      Future.microtask(() => _connect(user.id));
    }

    return const {};
  }

  void _connect(String userId) {
    _channel?.unsubscribe();
    final supabase = Supabase.instance.client;
    _channel = supabase.channel(
      'global-presence',
      opts: RealtimeChannelConfig(key: userId),
    );
    _channel!
      ..onPresenceSync((_) => _updateState())
      ..onPresenceJoin((_) => _updateState())
      ..onPresenceLeave((_) => _updateState())
      ..subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _channel!.track({});
        }
      });
  }

  void _updateState() {
    state = onlineUserIdsFromPresenceState(
      _channel?.presenceState() ?? [],
    );
  }

  void _disconnect() {
    _channel?.untrack();
    _channel?.unsubscribe();
    _channel = null;
    state = const {};
  }

  void untrack() {
    _channel?.untrack();
  }

  void track() {
    _channel?.track({});
    _updateState();
  }
}
