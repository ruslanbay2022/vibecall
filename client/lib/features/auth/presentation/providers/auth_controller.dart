import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  Stream<AuthState?> build() {
    return ref.watch(authRepositoryProvider).authStateChanges;
  }
}
