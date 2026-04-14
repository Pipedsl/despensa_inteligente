import 'package:despensa_inteligente/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateRedirect', () {
    // --- no logueado ---
    test('no logueado, va a / → /login', () {
      expect(
        calculateRedirect(isLoggedIn: false, hasHogar: null, location: '/'),
        '/login',
      );
    });

    test('no logueado, va a /despensa → /login', () {
      expect(
        calculateRedirect(
            isLoggedIn: false, hasHogar: null, location: '/despensa'),
        '/login',
      );
    });

    test('no logueado, ya en /login → null (no redirigir)', () {
      expect(
        calculateRedirect(
            isLoggedIn: false, hasHogar: null, location: '/login'),
        isNull,
      );
    });

    // --- logueado, sin hogar ---
    test('logueado, sin hogar, va a / → /onboarding/hogar', () {
      expect(
        calculateRedirect(isLoggedIn: true, hasHogar: false, location: '/'),
        '/onboarding/hogar',
      );
    });

    test('logueado, sin hogar, ya en /onboarding/hogar → null', () {
      expect(
        calculateRedirect(
            isLoggedIn: true,
            hasHogar: false,
            location: '/onboarding/hogar'),
        isNull,
      );
    });

    // --- logueado, con hogar ---
    test('logueado con hogar, en /login → /', () {
      expect(
        calculateRedirect(
            isLoggedIn: true, hasHogar: true, location: '/login'),
        '/',
      );
    });

    test('logueado con hogar, en /onboarding/hogar → /', () {
      expect(
        calculateRedirect(
            isLoggedIn: true,
            hasHogar: true,
            location: '/onboarding/hogar'),
        '/',
      );
    });

    test('logueado con hogar, en / → null (permitir)', () {
      expect(
        calculateRedirect(isLoggedIn: true, hasHogar: true, location: '/'),
        isNull,
      );
    });

    // --- logueado, hogar loading (null) ---
    test('logueado, hasHogar null (cargando), va a / → null (no redirigir)',
        () {
      expect(
        calculateRedirect(isLoggedIn: true, hasHogar: null, location: '/'),
        isNull,
      );
    });
  });

  group('buildRouter', () {
    test('crea el router sin errores', () {
      expect(
        () => buildRouter(isLoggedIn: () => false, hasHogar: () => null),
        returnsNormally,
      );
    });
  });
}
