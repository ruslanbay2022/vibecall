// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'VibeCall';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String environmentLabel(String env) {
    return 'среда: $env';
  }

  @override
  String get emailLabel => 'Электронная почта';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get displayNameLabel => 'Отображаемое имя (необязательно)';

  @override
  String get noAccount => 'Нет аккаунта?';

  @override
  String get hasAccount => 'Уже есть аккаунт?';

  @override
  String get checkYourEmail => 'Проверьте почту';

  @override
  String get confirmationSent =>
      'Мы отправили ссылку для подтверждения на вашу почту. Проверьте входящие и перейдите по ссылке.';

  @override
  String get resendConfirmation => 'Отправить повторно';

  @override
  String get backToSignIn => 'Вернуться ко входу';

  @override
  String get signOut => 'Выйти';

  @override
  String get invalidEmail => 'Введите корректный адрес электронной почты';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 6 символов';

  @override
  String authError(String message) {
    return 'Ошибка аутентификации: $message';
  }

  @override
  String get onboardingTitle => 'Выберите имя пользователя';

  @override
  String get onboardingBody => 'Онбординг — Шаг 1.6';

  @override
  String get usernameLabel => 'Имя пользователя';

  @override
  String get usernameRequired => 'Имя пользователя обязательно';

  @override
  String get usernameFormat =>
      'От 3 до 20 строчных букв, цифр или знаков подчёркивания';

  @override
  String get usernameTaken => 'Этот никнейм уже занят';

  @override
  String get displayNameRequired => 'Отображаемое имя обязательно';

  @override
  String get save => 'Сохранить';

  @override
  String onboardingError(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String get changeAvatar => 'Сменить аватар';

  @override
  String get bioLabel => 'О себе';

  @override
  String avatarUploadError(String message) {
    return 'Ошибка загрузки аватара: $message';
  }

  @override
  String get profileSaved => 'Профиль сохранён';

  @override
  String profileSaveError(String message) {
    return 'Ошибка сохранения профиля: $message';
  }

  @override
  String get contactsTitle => 'Контакты';

  @override
  String get contactsTab => 'Контакты';

  @override
  String get incomingTab => 'Входящие';

  @override
  String get outgoingTab => 'Исходящие';

  @override
  String get noContacts => 'Нет контактов';

  @override
  String get searchTitle => 'Поиск пользователей';

  @override
  String get searchHint => 'Поиск по имени или никнейму';

  @override
  String get searchAdd => 'Добавить';

  @override
  String get searchPending => 'Ожидание';

  @override
  String get searchIncoming => 'Входящая';

  @override
  String get searchInContacts => 'В контактах';

  @override
  String get searchRequestSent => 'Запрос отправлен';

  @override
  String get searchNoResults => 'Пользователи не найдены';

  @override
  String get searchAddError => 'Не удалось добавить пользователя';

  @override
  String get onlineStatus => 'В сети';

  @override
  String get offlineStatus => 'Не в сети';

  @override
  String get incomingCallTitle => 'Входящий звонок';

  @override
  String incomingCallFrom(String callerName) {
    return '$callerName звонит';
  }

  @override
  String get incomingCallVideo => 'Видеозвонок';

  @override
  String get incomingCallAudio => 'Аудиозвонок';

  @override
  String get acceptCall => 'Ответить';

  @override
  String get rejectCall => 'Отклонить';

  @override
  String get callConnecting => 'Подключение…';

  @override
  String callOutgoing(String name) {
    return 'Звонок $name…';
  }

  @override
  String get callEndedTitle => 'Звонок завершён';

  @override
  String get callEndedClose => 'Закрыть';

  @override
  String get callOutcomeAccepted => 'Звонок завершён';

  @override
  String get callOutcomeRejected => 'Отклонён';

  @override
  String get callOutcomeMissed => 'Пропущен';

  @override
  String get callOutcomeCancelled => 'Отменён';

  @override
  String get callOutcomeBusy => 'Занято';

  @override
  String get callOutcomeTimeout => 'Нет ответа';

  @override
  String get callEndButton => 'Завершить';

  @override
  String get callCancelButton => 'Отменить';

  @override
  String get callMute => 'Выкл. звук';

  @override
  String get callUnmute => 'Вкл. звук';

  @override
  String get callCameraOff => 'Выкл. камеру';

  @override
  String get callCameraOn => 'Вкл. камеру';

  @override
  String get callCameraEnableFailed =>
      'Камера недоступна — возможно, её использует собеседник или другое приложение';

  @override
  String get callSwitchCamera => 'Повернуть';

  @override
  String get callScreenShareStub => 'Экран';

  @override
  String get callVideoButton => 'Видеозвонок';

  @override
  String get callAudioButton => 'Аудиозвонок';
}
