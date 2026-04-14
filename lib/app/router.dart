import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';
import 'package:despensa_inteligente/features/auth/presentation/register_screen.dart';
import 'package:despensa_inteligente/features/hogares/presentation/onboarding_hogar_screen.dart';
import 'package:despensa_inteligente/features/hogares/presentation/mis_hogares_screen.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';

typedef IsLoggedIn = bool Function();
typedef HasHogar = bool? Function();

/// Lógica de redirección pura — testeable sin instanciar GoRouter.
/// [hasHogar] es null cuando el estado está cargando (no redirigir).
String? calculateRedirect({
  required bool isLoggedIn,
  required bool? hasHogar,
  required String location,
}) {
  final goingToLogin = location == '/login';
  final goingToRegistro = location == '/registro';
  final goingToOnboarding = location == '/onboarding/hogar';
  final publicRoutes = goingToLogin || goingToRegistro;

  if (!isLoggedIn && !publicRoutes) return '/login';
  if (!isLoggedIn && publicRoutes) return null;

  // Logueado desde aquí
  if (goingToLogin || goingToRegistro) return '/';

  // hasHogar == null → cargando; no redirigir todavía
  if (hasHogar == null) return null;

  if (!hasHogar && !goingToOnboarding) return '/onboarding/hogar';
  if (hasHogar && goingToOnboarding) return '/';

  return null;
}

GoRouter buildRouter({
  required IsLoggedIn isLoggedIn,
  required HasHogar hasHogar,
}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      return calculateRedirect(
        isLoggedIn: isLoggedIn(),
        hasHogar: hasHogar(),
        location: state.matchedLocation,
      );
    },
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/onboarding/hogar',
          builder: (_, __) => const OnboardingHogarScreen()),
      GoRoute(
          path: '/hogares', builder: (_, __) => const MisHogaresScreen()),
    ],
  );
}
