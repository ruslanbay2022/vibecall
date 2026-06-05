import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vibecall/app/router.dart';
import 'package:vibecall/app/theme.dart';
import 'package:vibecall/features/chat/presentation/widgets/chat_notification_listener.dart';
import 'package:vibecall/features/presence/presentation/presence_lifecycle_handler.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class VibeCallApp extends StatelessWidget {
  const VibeCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    // SentryWidget wraps the whole app so it can observe widget-tree errors
    // and gestures above MaterialApp. ProviderScope is created exactly once
    // in main.dart — do NOT create another one here (would shadow the outer
    // one and silently split provider state between root and routes).
    return SentryWidget(
      child: PresenceLifecycleHandler(
        child: ChatNotificationListener(
          child: MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            routerConfig: router,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
  }
}
