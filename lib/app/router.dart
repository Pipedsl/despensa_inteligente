import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';

typedef IsLoggedIn = bool Function();

/// Pure function with redirect logic — testeable sin instanciar GoRouter.
String? calculateRedirect({
  required bool isLoggedIn,
  required String location,
}) {
  final goingToLogin = location == '/login';
  if (!isLoggedIn && !goingToLogin) return '/login';
  if (isLoggedIn && goingToLogin) return '/';
  return null;
}

GoRouter buildRouter({required IsLoggedIn isLoggedIn}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      return calculateRedirect(
        isLoggedIn: isLoggedIn(),
        location: state.matchedLocation,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
    ],
  );
}
