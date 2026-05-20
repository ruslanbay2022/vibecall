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
}
