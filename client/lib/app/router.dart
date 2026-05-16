import 'package:go_router/go_router.dart';
import 'package:vibecall/features/home/presentation/home_placeholder_screen.dart';

// Top-level `final` — single GoRouter instance for the app lifetime.
// A getter (`GoRouter get router => GoRouter(...)`) would rebuild the router
// (and reset navigation stack / current location) on every access.
final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePlaceholderScreen(),
    ),
  ],
);
