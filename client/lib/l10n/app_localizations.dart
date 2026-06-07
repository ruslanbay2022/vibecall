import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title shown in the app bar and OS task switcher
  ///
  /// In en, this message translates to:
  /// **'VibeCall'**
  String get appTitle;

  /// Button to navigate to the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Button to navigate to the sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Label showing the current build environment (dev/prod)
  ///
  /// In en, this message translates to:
  /// **'env: {env}'**
  String environmentLabel(String env);

  /// Label for the email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label for the password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label for the optional display name input field
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameLabel;

  /// Text shown before the sign-up link on the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Text shown before the sign-in link on the sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get hasAccount;

  /// Title of the confirmation email screen
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// Message shown after successful sign-up
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to your email. Please check your inbox and follow the link.'**
  String get confirmationSent;

  /// Button to resend the confirmation email
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation'**
  String get resendConfirmation;

  /// Link to return to the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// Button to sign out of the application
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Error shown when the email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// Error shown when the password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Generic authentication error message
  ///
  /// In en, this message translates to:
  /// **'Authentication error: {message}'**
  String authError(String message);

  /// Title of the onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get onboardingTitle;

  /// Body text of the onboarding placeholder screen
  ///
  /// In en, this message translates to:
  /// **'Onboarding — Step 1.6'**
  String get onboardingBody;

  /// Label for the username input field on onboarding
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Error when username field is empty
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// Error when username format is invalid
  ///
  /// In en, this message translates to:
  /// **'3-20 lowercase letters, digits, or underscores'**
  String get usernameFormat;

  /// Error when username is not available
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get usernameTaken;

  /// Error when display name field is empty
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get displayNameRequired;

  /// Button text for saving onboarding form
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Error message shown when onboarding submit fails
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String onboardingError(String message);

  /// Title of the profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Button to change the user's avatar
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get changeAvatar;

  /// Label for the bio input field
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// Error shown when avatar upload fails
  ///
  /// In en, this message translates to:
  /// **'Avatar upload error: {message}'**
  String avatarUploadError(String message);

  /// Success message when profile is saved
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// Error shown when profile save fails
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {message}'**
  String profileSaveError(String message);

  /// Title of the contacts screen
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// Tab label for accepted contacts
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTab;

  /// Tab label for incoming requests
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get incomingTab;

  /// Tab label for outgoing requests
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get outgoingTab;

  /// Shown when contacts list is empty
  ///
  /// In en, this message translates to:
  /// **'No contacts'**
  String get noContacts;

  /// Title of the search screen
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get searchTitle;

  /// Hint text in the search field
  ///
  /// In en, this message translates to:
  /// **'Search by username or display name'**
  String get searchHint;

  /// Button to add a user as a contact
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get searchAdd;

  /// Status shown when the outgoing request is pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get searchPending;

  /// Status shown when an incoming request exists
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get searchIncoming;

  /// Status shown when the user is already a contact
  ///
  /// In en, this message translates to:
  /// **'In Contacts'**
  String get searchInContacts;

  /// Success message when a contact request is sent
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get searchRequestSent;

  /// Shown when search yields no results
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get searchNoResults;

  /// Error shown when adding a contact fails
  ///
  /// In en, this message translates to:
  /// **'Could not add user'**
  String get searchAddError;

  /// Status label shown when a contact is online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// Status label shown when a contact is offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;

  /// Title of the incoming call overlay
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get incomingCallTitle;

  /// Message shown when someone is calling
  ///
  /// In en, this message translates to:
  /// **'{callerName} is calling'**
  String incomingCallFrom(String callerName);

  /// Label shown when the incoming call is a video call
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get incomingCallVideo;

  /// Label shown when the incoming call is an audio call
  ///
  /// In en, this message translates to:
  /// **'Audio call'**
  String get incomingCallAudio;

  /// Button to accept an incoming call
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptCall;

  /// Button to reject an incoming call
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectCall;

  /// Label shown while connecting to a call
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get callConnecting;

  /// Label shown while calling someone
  ///
  /// In en, this message translates to:
  /// **'Calling {name}…'**
  String callOutgoing(String name);

  /// Title of the call ended screen
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEndedTitle;

  /// Button to close the ended call screen
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get callEndedClose;

  /// Label when a call was accepted and then ended
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callOutcomeAccepted;

  /// Label when a call was rejected
  ///
  /// In en, this message translates to:
  /// **'Call rejected'**
  String get callOutcomeRejected;

  /// Label when a call was missed
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get callOutcomeMissed;

  /// Label when a call was cancelled
  ///
  /// In en, this message translates to:
  /// **'Call cancelled'**
  String get callOutcomeCancelled;

  /// Label when the callee is busy
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get callOutcomeBusy;

  /// Label when the call timed out
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get callOutcomeTimeout;

  /// Button to end an active call
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get callEndButton;

  /// Button to cancel an outgoing call
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get callCancelButton;

  /// Button to mute microphone
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get callMute;

  /// Button to unmute microphone
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get callUnmute;

  /// Button to turn camera off
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get callCameraOff;

  /// Button to turn camera on
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get callCameraOn;

  /// Snackbar when local camera cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable — it may be in use by the other participant or another app'**
  String get callCameraEnableFailed;

  /// Button to switch between front and back camera
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get callSwitchCamera;

  /// Button to start screen share
  ///
  /// In en, this message translates to:
  /// **'Share screen'**
  String get callScreenShare;

  /// Button to stop screen share
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get callStopScreenShare;

  /// Snackbar when screen share cannot be enabled
  ///
  /// In en, this message translates to:
  /// **'Screen share unavailable — it may be in use by another app or denied by system'**
  String get callScreenShareEnableFailed;

  /// Deprecated: use callScreenShare instead
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get callScreenShareStub;

  /// Accessibility label for video call button on contacts
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get callVideoButton;

  /// Accessibility label for audio call button on contacts
  ///
  /// In en, this message translates to:
  /// **'Audio call'**
  String get callAudioButton;

  /// Title of the call history screen
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callHistoryTitle;

  /// Link to call history from home
  ///
  /// In en, this message translates to:
  /// **'Call history'**
  String get callHistoryLink;

  /// Tab label showing all call history entries
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get callHistoryTabAll;

  /// Tab label showing only missed and timed-out calls
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get callHistoryTabMissed;

  /// Empty state for the call history list
  ///
  /// In en, this message translates to:
  /// **'No calls yet'**
  String get callHistoryEmpty;

  /// Empty state for the missed calls filter
  ///
  /// In en, this message translates to:
  /// **'No missed calls'**
  String get callHistoryMissedEmpty;

  /// Error state for the call history list
  ///
  /// In en, this message translates to:
  /// **'Failed to load call history'**
  String get callHistoryError;

  /// Button to retry loading call history after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get callHistoryRetry;

  /// Duration of an accepted call in mm:ss format
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds}'**
  String callHistoryDuration(String minutes, String seconds);

  /// Confirmation before calling a peer from call history
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String callHistoryCallPrompt(String name);

  /// Dismiss call confirmation from call history
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get callHistoryCallCancel;

  /// Title of the conversations list screen
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// Link to chats from home
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsLink;

  /// Empty state when there are no conversations
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoConversations;

  /// Empty state when a conversation has no messages
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get chatEmpty;

  /// Hint text in the chat message input field
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatInputHint;

  /// Button to send a chat message
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// Accessibility label for outgoing message being sent
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get chatMessageStatusSending;

  /// Accessibility label for outgoing message sent to server
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatMessageStatusSent;

  /// Accessibility label for outgoing message delivered to recipient
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatMessageStatusDelivered;

  /// Accessibility label for outgoing message read by recipient
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatMessageStatusRead;

  /// Snackbar when sending a chat message fails
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get chatSendError;

  /// Indicator shown when peer is typing
  ///
  /// In en, this message translates to:
  /// **'{name} is typing…'**
  String chatTyping(String name);

  /// Snackbar text when tapping the attach button stub
  ///
  /// In en, this message translates to:
  /// **'Attachments coming soon'**
  String get chatAttachStub;

  /// Snackbar text when tapping the voice message button stub
  ///
  /// In en, this message translates to:
  /// **'Voice messages coming soon'**
  String get chatVoiceStub;

  /// Error state when messages fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get chatLoadError;

  /// Button to retry loading messages after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chatRetry;

  /// Chat icon tooltip / label on contacts screen
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chatStartConversation;

  /// Accessibility label for unread message count badge
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages'**
  String chatUnreadBadge(int count);

  /// Button label to open in-call chat sheet
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get callOpenChat;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
