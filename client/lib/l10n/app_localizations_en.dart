// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VibeCall';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String environmentLabel(String env) {
    return 'env: $env';
  }

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameLabel => 'Display name (optional)';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get confirmationSent =>
      'We sent a confirmation link to your email. Please check your inbox and follow the link.';

  @override
  String get resendConfirmation => 'Resend confirmation';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String authError(String message) {
    return 'Authentication error: $message';
  }
}
