import 'package:despensa_inteligente/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateRedirect', () {
    test('redirige a /login cuando no hay sesión y va a /', () {
      final result = calculateRedirect(isLoggedIn: false, location: '/');
      expect(result, '/login');
    });

    test('redirige a /login cuando no hay sesión y va a ruta protegida', () {
      final result =
          calculateRedirect(isLoggedIn: false, location: '/despensa');
      expect(result, '/login');
    });

    test('redirige a / cuando hay sesión y el usuario va a /login', () {
      final result = calculateRedirect(isLoggedIn: true, location: '/login');
      expect(result, '/');
    });

    test('no redirige cuando hay sesión y el usuario va a /', () {
      final result = calculateRedirect(isLoggedIn: true, location: '/');
      expect(result, isNull);
    });

    test('no redirige cuando no hay sesión y el usuario ya va a /login', () {
      final result =
          calculateRedirect(isLoggedIn: false, location: '/login');
      expect(result, isNull);
    });
  });

  group('buildRouter', () {
    test('devuelve una instancia de GoRouter sin errores', () {
      expect(() => buildRouter(isLoggedIn: () => false), returnsNormally);
      expect(() => buildRouter(isLoggedIn: () => true), returnsNormally);
    });
  });
}
