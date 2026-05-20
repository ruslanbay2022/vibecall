import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_repository.g.dart';

abstract class AuthRepository {
  Future<void> signUp(String email, String password, {String? displayName});
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> resendConfirmation(String email);
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
}

class SupabaseAuthRepository implements AuthRepository {
  final GoTrueClient _client;

  SupabaseAuthRepository({GoTrueClient? client})
      : _client = client ?? Supabase.instance.client.auth;

  @override
  Future<void> signUp(String email, String password, {String? displayName}) async {
    await _client.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );
  }

  @override
  Future<void> signIn(String email, String password) async {
    await _client.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.signOut();
  }

  @override
  Future<void> resendConfirmation(String email) async {
    await _client.resend(type: OtpType.signup, email: email);
  }

  @override
  Stream<AuthState> get authStateChanges => _client.onAuthStateChange;

  @override
  User? get currentUser => _client.currentUser;
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository();
}
