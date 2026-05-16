import 'package:go_router/go_router.dart';
import 'package:vibecall/features/home/presentation/home_placeholder_screen.dart';

GoRouter get router => GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePlaceholderScreen(),
    ),
  ],
);
