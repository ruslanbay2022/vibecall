import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibecall/features/auth/presentation/screens/confirm_email_screen.dart';
import 'package:vibecall/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:vibecall/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:vibecall/features/contacts/presentation/screens/contacts_screen.dart';
import 'package:vibecall/features/call/presentation/widgets/call_app_shell.dart';
import 'package:vibecall/features/home/presentation/home_placeholder_screen.dart';
import 'package:vibecall/features/search/presentation/screens/search_screen.dart';
import 'package:vibecall/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:vibecall/features/profile/presentation/screens/profile_screen.dart';

class AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  AuthChangeNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _authNotifier = AuthChangeNotifier();

final GoRouter router = GoRouter(
  refreshListenable: _authNotifier,
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthenticated = session != null;
    final location = state.matchedLocation;
    final isAuthRoute = location == '/sign-in' ||
        location == '/sign-up' ||
        location == '/confirm-email';

    if (!isAuthenticated && !isAuthRoute) {
      return '/sign-in';
    }

    if (isAuthenticated) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', session.user.id)
          .maybeSingle();
      final username = response?['username'] as String?;
      if (username != null && username.startsWith('user_')) {
        if (location != '/onboarding') return '/onboarding';
      } else {
        if (isAuthRoute || location == '/onboarding') return '/home';
      }
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/confirm-email',
      builder: (context, state) => const ConfirmEmailScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => CallAppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePlaceholderScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/contacts',
          builder: (context, state) => const ContactsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/',
      redirect: (context, state) => '/home',
    ),
  ],
);
