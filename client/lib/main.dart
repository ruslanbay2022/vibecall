import 'package:flutter/material.dart';
import 'package:vibecall/app/env.dart';
import 'package:vibecall/l10n/app_localizations.dart';

void main() {
  Env.assertAll();
  runApp(const _VibeCallBootstrap());
}

class _VibeCallBootstrap extends StatelessWidget {
  const _VibeCallBootstrap();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appTitle),
            const SizedBox(height: 8),
            Text(
              l10n.environmentLabel(Env.env),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
