import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class ConfirmEmailScreen extends ConsumerWidget {
  const ConfirmEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.checkYourEmail,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.confirmationSent,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Resend confirmation — user should be authenticated here
                  final user = ref.read(authRepositoryProvider).currentUser;
                  if (user != null) {
                    ref.read(authRepositoryProvider).resendConfirmation(user.email!);
                  }
                },
                child: Text(l10n.resendConfirmation),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/sign-in'),
                child: Text(l10n.backToSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
