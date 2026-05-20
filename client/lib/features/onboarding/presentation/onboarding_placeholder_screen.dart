import 'package:flutter/material.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class OnboardingPlaceholderScreen extends StatelessWidget {
  const OnboardingPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: Center(child: Text(l10n.onboardingBody)),
    );
  }
}
