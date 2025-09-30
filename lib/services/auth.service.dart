import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Instancia de Firebase Auth
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

// 2. Stream del estado de autenticación (para AuthWrapper)
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// 3. ViewModel/Service para la lógica de Auth
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  // Iniciar Sesión con Email y Password
  Future<User?> signIn(String email, String password) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return creds.user;
    } on FirebaseAuthException catch (e) {
      // Manejo de errores específicos (e.g. 'user-not-found', 'wrong-password')
      throw Exception(e.message ?? 'Error al iniciar sesión');
    }
  }

  // Registrar Usuario
  Future<User?> signUp(String email, String password) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // **TO-DO:** Guardar datos adicionales en Firestore (colección 'usuarios')
      return creds.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error al registrar usuario');
    }
  }

  // Iniciar Sesión como Usuario de Test
  Future<User?> signInAsTestUser() async {
    // Utiliza una cuenta de Firebase dedicada (ej: 'test@despensa.cl')
    // **NOTA:** La contraseña debe ser segura y no hardcodeada en producción real.
    // Para MVP, la hardcodeamos temporalmente.
    const testEmail = 'test@despensa.cl';
    const testPassword = 'PasswordDeTestSegura123';
    try {
      return await signIn(testEmail, testPassword);
    } catch (e) {
      // Si el usuario de prueba no existe, lo creamos
      if (e.toString().contains('user-not-found')) {
        final user = await signUp(testEmail, testPassword);
        // **TO-DO:** Asegurarse de marcarlo en Firestore como 'is_test_user: true'
        return user;
      }
      rethrow;
    }
  }

  // Cerrar Sesión
  Future<void> signOut() => _auth.signOut();
}

// 4. Provider de la clase de servicio (patrón de inyección)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});
