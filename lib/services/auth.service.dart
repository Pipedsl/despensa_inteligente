import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth;
  final UsuarioRepository _usuarioRepo;

  AuthService(this._auth, this._usuarioRepo);

  Future<User?> signIn(String email, String password) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (creds.user != null) {
        await _usuarioRepo.crearSiNoExiste(
          uid: creds.user!.uid,
          email: creds.user!.email ?? email,
          displayName: creds.user!.displayName ?? email.split('@').first,
        );
      }
      return creds.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error al iniciar sesión');
    }
  }

  Future<User?> signUp(String email, String password,
      {String? displayName}) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (creds.user != null) {
        final name = displayName ?? email.split('@').first;
        await creds.user!.updateDisplayName(name);
        await _usuarioRepo.crear(
          uid: creds.user!.uid,
          email: email,
          displayName: name,
        );
      }
      return creds.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error al registrar usuario');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      final result = await _auth.signInWithPopup(provider);
      if (result.user != null) {
        await _usuarioRepo.crearSiNoExiste(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          displayName: result.user!.displayName ?? '',
          photoUrl: result.user!.photoURL,
        );
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Error con Google Sign-In');
    }
  }

  Future<User?> signInAsTestUser() async {
    const testEmail = 'test@despensa.cl';
    const testPassword = 'PasswordDeTestSegura123';
    try {
      return await signIn(testEmail, testPassword);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('user-not-found') ||
          msg.contains('INVALID_LOGIN_CREDENTIALS') ||
          msg.contains('invalid-credential') ||
          msg.contains('auth credential is incorrect')) {
        return await signUp(testEmail, testPassword,
            displayName: 'Usuario Test');
      }
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(usuarioRepositoryProvider),
  );
});
