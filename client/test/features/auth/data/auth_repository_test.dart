import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthState extends Mock implements AuthState {}

void main() {
  late MockGoTrueClient mockClient;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(OtpType.signup);
  });

  setUp(() {
    mockClient = MockGoTrueClient();
    repository = SupabaseAuthRepository(client: mockClient);
  });

  test('signUp calls GoTrueClient.signUp with email and password', () async {
    when(() => mockClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        )).thenAnswer((_) async => AuthResponse());

    await repository.signUp('test@example.com', 'password123');

    verify(() => mockClient.signUp(
          email: 'test@example.com',
          password: 'password123',
          data: null,
        )).called(1);
  });

  test('signUp passes display_name metadata when provided', () async {
    when(() => mockClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        )).thenAnswer((_) async => AuthResponse());

    await repository.signUp(
      'test@example.com',
      'password123',
      displayName: 'Alice',
    );

    verify(() => mockClient.signUp(
          email: 'test@example.com',
          password: 'password123',
          data: {'display_name': 'Alice'},
        )).called(1);
  });

  test('signIn calls GoTrueClient.signInWithPassword', () async {
    when(() => mockClient.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => AuthResponse());

    await repository.signIn('test@example.com', 'password123');

    verify(() => mockClient.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
  });

  test('signOut calls GoTrueClient.signOut', () async {
    when(() => mockClient.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => mockClient.signOut()).called(1);
  });

  test('resendConfirmation calls GoTrueClient.resend', () async {
    when(() => mockClient.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
        )).thenAnswer((_) async => ResendResponse());

    await repository.resendConfirmation('test@example.com');

    verify(() => mockClient.resend(
          type: OtpType.signup,
          email: 'test@example.com',
        )).called(1);
  });
}
