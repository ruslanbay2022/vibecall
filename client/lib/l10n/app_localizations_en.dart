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

  @override
  String get incomingCallTitle => 'Incoming call';

  @override
  String incomingCallFrom(String callerName) {
    return '$callerName is calling';
  }

  @override
  String get incomingCallVideo => 'Video call';

  @override
  String get incomingCallAudio => 'Audio call';

  @override
  String get acceptCall => 'Accept';

  @override
  String get rejectCall => 'Reject';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String callOutgoing(String name) {
    return 'Calling $name…';
  }

  @override
  String get callEndedTitle => 'Call ended';

  @override
  String get callEndedClose => 'Close';

  @override
  String get callOutcomeAccepted => 'Call ended';

  @override
  String get callOutcomeRejected => 'Call rejected';

  @override
  String get callOutcomeMissed => 'Missed call';

  @override
  String get callOutcomeCancelled => 'Call cancelled';

  @override
  String get callOutcomeBusy => 'Busy';

  @override
  String get callOutcomeTimeout => 'No answer';

  @override
  String get callEndButton => 'End';

  @override
  String get callCancelButton => 'Cancel';

  @override
  String get callMute => 'Mute';

  @override
  String get callUnmute => 'Unmute';

  @override
  String get callCameraOff => 'Camera off';

  @override
  String get callCameraOn => 'Camera on';

  @override
  String get callCameraEnableFailed =>
      'Camera unavailable — it may be in use by the other participant or another app';

  @override
  String get callSwitchCamera => 'Flip';

  @override
  String get callScreenShareStub => 'Share';

  @override
  String get callVideoButton => 'Video call';

  @override
  String get callAudioButton => 'Audio call';

  @override
  String get callHistoryTitle => 'Call history';

  @override
  String get callHistoryLink => 'Call history';

  @override
  String get callHistoryTabAll => 'All';

  @override
  String get callHistoryTabMissed => 'Missed';

  @override
  String get callHistoryEmpty => 'No calls yet';

  @override
  String get callHistoryMissedEmpty => 'No missed calls';

  @override
  String get callHistoryError => 'Failed to load call history';

  @override
  String get callHistoryRetry => 'Retry';

  @override
  String callHistoryDuration(String minutes, String seconds) {
    return '$minutes:$seconds';
  }

  @override
  String callHistoryCallPrompt(String name) {
    return 'Call $name';
  }

  @override
  String get callHistoryCallCancel => 'Cancel';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsLink => 'Chats';

  @override
  String get chatNoConversations => 'No conversations yet';

  @override
  String get chatInputHint => 'Type a message…';

  @override
  String get chatSend => 'Send';

  @override
  String chatTyping(String name) {
    return '$name is typing…';
  }

  @override
  String get chatAttachStub => 'Attachments coming soon';

  @override
  String get chatVoiceStub => 'Voice messages coming soon';

  @override
  String get chatLoadError => 'Failed to load messages';

  @override
  String get chatRetry => 'Retry';

  @override
  String get chatStartConversation => 'Start a conversation';
}
