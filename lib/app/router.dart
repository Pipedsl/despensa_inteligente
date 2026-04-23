import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';
import 'package:despensa_inteligente/features/auth/presentation/register_screen.dart';
import 'package:despensa_inteligente/features/hogares/presentation/onboarding_hogar_screen.dart';
import 'package:despensa_inteligente/features/hogares/presentation/mis_hogares_screen.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/despensa/presentation/despensa_screen.dart';
import 'package:despensa_inteligente/features/despensa/presentation/agregar_item_screen.dart';
import 'package:despensa_inteligente/features/despensa/presentation/detalle_item_screen.dart';
import 'package:despensa_inteligente/features/recetas/presentation/recetas_screen.dart';
import 'package:despensa_inteligente/features/recetas/presentation/detalle_receta_screen.dart';
import 'package:despensa_inteligente/features/recetas/presentation/upgrade_screen.dart';
import 'package:despensa_inteligente/features/productos_globales/presentation/proponer_producto_screen.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';

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
      GoRoute(path: '/despensa', builder: (_, __) => const DespensaScreen()),
      GoRoute(
        path: '/despensa/agregar',
        builder: (_, state) => AgregarItemScreen(item: state.extra as ItemDespensa?),
      ),
      GoRoute(
        path: '/despensa/:id',
        builder: (_, state) => DetalleItemScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/recetas', builder: (_, __) => const RecetasScreen()),
      GoRoute(
        path: '/recetas/:id',
        builder: (_, state) {
          final receta = state.extra as Receta?;
          if (receta == null) return const RecetasScreen();
          return DetalleRecetaScreen(receta: receta);
        },
      ),
      GoRoute(path: '/upgrade', builder: (_, __) => const UpgradeScreen()),
      GoRoute(
        path: '/proponer-producto',
        builder: (_, state) {
          final barcode = state.uri.queryParameters['barcode'] ?? '';
          return ProponerProductoScreen(barcode: barcode);
        },
      ),
    ],
  );
}
