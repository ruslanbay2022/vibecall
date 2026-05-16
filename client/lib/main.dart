import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/app/app.dart';
import 'package:vibecall/app/env.dart';
import 'package:vibecall/core/error/sentry_filter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertAll();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  if (Env.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        options.beforeSend = stripPii;
        options.environment = Env.env;
      },
      appRunner: () => runApp(const ProviderScope(child: VibeCallApp())),
    );
  } else {
    runApp(const ProviderScope(child: VibeCallApp()));
  }
}
