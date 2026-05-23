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

  @override
  String get onboardingTitle => 'Choose a username';

  @override
  String get onboardingBody => 'Onboarding — Step 1.6';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameFormat => '3-20 lowercase letters, digits, or underscores';

  @override
  String get usernameTaken => 'This username is already taken';

  @override
  String get displayNameRequired => 'Display name is required';

  @override
  String get save => 'Save';

  @override
  String onboardingError(String message) {
    return 'Error: $message';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get bioLabel => 'Bio';

  @override
  String avatarUploadError(String message) {
    return 'Avatar upload error: $message';
  }

  @override
  String get profileSaved => 'Profile saved';

  @override
  String profileSaveError(String message) {
    return 'Error saving profile: $message';
  }

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsTab => 'Contacts';

  @override
  String get incomingTab => 'Incoming';

  @override
  String get outgoingTab => 'Outgoing';

  @override
  String get noContacts => 'No contacts';

  @override
  String get searchTitle => 'Search users';

  @override
  String get searchHint => 'Search by username or display name';

  @override
  String get searchAdd => 'Add';

  @override
  String get searchPending => 'Pending';

  @override
  String get searchIncoming => 'Incoming';

  @override
  String get searchInContacts => 'In Contacts';

  @override
  String get searchRequestSent => 'Request sent';

  @override
  String get searchNoResults => 'No users found';

  @override
  String get searchAddError => 'Could not add user';

  @override
  String get onlineStatus => 'Online';

  @override
  String get offlineStatus => 'Offline';
}
