# Fase 1 — Auth real + Hogar multitenant — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un usuario puede registrarse (email o Google), crear un hogar, invitar a otro miembro por código de 6 caracteres, y ambos ven el mismo hogar en el dashboard — con reglas Firestore que impiden acceso cruzado entre hogares.

**Architecture:** Capa de dominio pura (`Usuario`, `Hogar` como clases Dart inmutables) + capa de datos (`UsuarioRepository`, `HogarRepository` que reciben `FirebaseFirestore` via Riverpod) + capa de presentación (screens) + guard en el router que redirige usuarios sin hogar a `/onboarding/hogar`. Los providers de Firebase son sobreescribibles en tests usando `FakeFirebaseFirestore` de `fake_cloud_firestore`.

**Tech Stack:** Flutter Web, `flutter_riverpod` 3, `cloud_firestore`, `firebase_auth`, `go_router` 16, `fake_cloud_firestore` 3 (dev).

**Branch:** `feature/fase-1-auth-hogar`

**Prerequisitos manuales:**
- En Firebase Console → Authentication → Sign-in method: activar Email/Password y Google.
- En Firebase Console → Google Sign-In → agregar dominio autorizado `localhost` (para dev) y el dominio de Hosting (para prod).
- La cuenta de test `test@despensa.cl` debe existir en Firebase Auth del proyecto real, o usar el emulador.

---

## File Structure

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `pubspec.yaml` | Modificar | Agregar `fake_cloud_firestore` a dev_dependencies |
| `lib/services/firebase/firestore_provider.dart` | Crear | Provider de `FirebaseFirestore` sobreescribible en tests |
| `lib/features/auth/domain/usuario.dart` | Crear | Modelo `Usuario` inmutable con `fromFirestore`/`toMap` |
| `lib/features/auth/data/usuario_repository.dart` | Crear | CRUD sobre `/usuarios/{uid}` + Riverpod provider |
| `lib/features/auth/presentation/register_screen.dart` | Crear | Pantalla de registro email+contraseña+nombre |
| `lib/features/auth/presentation/login_screen.dart` | Modificar | Agregar botón Google Sign-In + link a registro |
| `lib/features/hogares/domain/hogar.dart` | Crear | Modelos `Hogar` e `Invitacion` con `fromFirestore`/`toMap` |
| `lib/features/hogares/data/hogar_repository.dart` | Crear | CRUD hogares + lógica invitaciones + Riverpod provider |
| `lib/features/hogares/presentation/onboarding_hogar_screen.dart` | Crear | Primera pantalla tras registro: crear hogar |
| `lib/features/hogares/presentation/mis_hogares_screen.dart` | Crear | Lista de hogares, crear, generar código, unirse |
| `lib/features/home/presentation/dashboard_screen.dart` | Modificar | Mostrar nombre del hogar activo y link a mis hogares |
| `lib/app/router.dart` | Modificar | `calculateRedirect` con `hasHogar bool?`, rutas nuevas |
| `lib/main.dart` | Modificar | Pasar `hasHogar` al router via `usuarioStreamProvider` |
| `firestore.rules` | Modificar | Reglas multitenant por hogar |
| `test/features/auth/usuario_repository_test.dart` | Crear | Tests con `FakeFirebaseFirestore` |
| `test/features/hogares/hogar_repository_test.dart` | Crear | Tests con `FakeFirebaseFirestore` |
| `test/features/auth/register_screen_test.dart` | Crear | Widget test de la pantalla de registro |
| `test/features/hogares/onboarding_hogar_screen_test.dart` | Crear | Widget test del onboarding |
| `test/app/router_test.dart` | Modificar | Tests actualizados de `calculateRedirect` con `hasHogar` |

---

## Task 1: Agregar dependencias de test y provider de Firestore

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/firebase/firestore_provider.dart`

- [ ] **Step 1.1: Agregar `fake_cloud_firestore` a pubspec.yaml**

Abrir `pubspec.yaml` y agregar bajo `dev_dependencies:`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  fake_cloud_firestore: ^3.0.0
```

- [ ] **Step 1.2: Correr `flutter pub get`**

Run: `flutter pub get`
Expected: `Got dependencies!` sin errores.

- [ ] **Step 1.3: Crear `lib/services/firebase/firestore_provider.dart`**

```bash
mkdir -p lib/services/firebase
```

Write `lib/services/firebase/firestore_provider.dart`:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);
```

- [ ] **Step 1.4: Verificar análisis**

Run: `flutter analyze lib/services/firebase/firestore_provider.dart`
Expected: `No issues found!`

- [ ] **Step 1.5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/firebase/firestore_provider.dart
git commit -m "chore(fase-1): add fake_cloud_firestore dev dep and firestoreProvider"
```

---

## Task 2: Modelo `Usuario`

**Files:**
- Create: `lib/features/auth/domain/usuario.dart`
- Create: `test/features/auth/usuario_test.dart`

- [ ] **Step 2.1: Escribir el test primero**

```bash
mkdir -p test/features/auth
```

Write `test/features/auth/usuario_test.dart`:
```dart
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Usuario', () {
    test('fromFirestore parsea correctamente los campos', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('usuarios').doc('uid123').set({
        'email': 'test@test.cl',
        'displayName': 'Felipe',
        'plan': 'free',
        'hogarActivo': null,
        'createdAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      });

      final snap =
          await firestore.collection('usuarios').doc('uid123').get();
      final usuario = Usuario.fromFirestore(snap);

      expect(usuario.uid, 'uid123');
      expect(usuario.email, 'test@test.cl');
      expect(usuario.plan, 'free');
      expect(usuario.hogarActivo, isNull);
    });

    test('toMap incluye todos los campos requeridos', () {
      final usuario = Usuario(
        uid: 'uid1',
        email: 'a@b.cl',
        displayName: 'Ana',
        plan: 'free',
        hogarActivo: null,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = usuario.toMap();
      expect(map['email'], 'a@b.cl');
      expect(map['plan'], 'free');
      expect(map.containsKey('createdAt'), isTrue);
    });
  });
}
```

- [ ] **Step 2.2: Correr el test y verificar que falla**

Run: `flutter test test/features/auth/usuario_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 2.3: Crear `lib/features/auth/domain/usuario.dart`**

Write:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String plan; // "free" | "pro"
  final String? hogarActivo;
  final DateTime createdAt;

  const Usuario({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.plan,
    this.hogarActivo,
    required this.createdAt,
  });

  factory Usuario.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return Usuario(
      uid: snap.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      plan: data['plan'] as String? ?? 'free',
      hogarActivo: data['hogarActivo'] as String?,
      createdAt: data['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'plan': plan,
        'hogarActivo': hogarActivo,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  Usuario copyWith({String? hogarActivo}) => Usuario(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        plan: plan,
        hogarActivo: hogarActivo ?? this.hogarActivo,
        createdAt: createdAt,
      );
}
```

- [ ] **Step 2.4: Correr el test y verificar que pasa**

Run: `flutter test test/features/auth/usuario_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 2.5: Commit**

```bash
git add lib/features/auth/domain/usuario.dart test/features/auth/usuario_test.dart
git commit -m "feat(fase-1): add Usuario domain model with fromFirestore/toMap"
```

---

## Task 3: `UsuarioRepository`

**Files:**
- Create: `lib/features/auth/data/usuario_repository.dart`
- Create: `test/features/auth/usuario_repository_test.dart`

- [ ] **Step 3.1: Escribir los tests primero**

Write `test/features/auth/usuario_repository_test.dart`:
```dart
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UsuarioRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = UsuarioRepository(firestore);
  });

  group('UsuarioRepository', () {
    test('crear guarda el documento en /usuarios/{uid}', () async {
      await repo.crear(
        uid: 'uid1',
        email: 'a@b.cl',
        displayName: 'Ana',
      );

      final snap =
          await firestore.collection('usuarios').doc('uid1').get();
      expect(snap.exists, isTrue);
      expect(snap['email'], 'a@b.cl');
      expect(snap['plan'], 'free');
      expect(snap['hogarActivo'], isNull);
    });

    test('obtener retorna null si el documento no existe', () async {
      final result = await repo.obtener('uid_inexistente');
      expect(result, isNull);
    });

    test('obtener retorna el Usuario si existe', () async {
      await repo.crear(
          uid: 'uid2', email: 'b@c.cl', displayName: 'Beto');
      final result = await repo.obtener('uid2');

      expect(result, isNotNull);
      expect(result!.email, 'b@c.cl');
      expect(result.plan, 'free');
    });

    test('actualizarHogarActivo persiste el hogarId', () async {
      await repo.crear(uid: 'uid3', email: 'c@d.cl', displayName: 'Cata');
      await repo.actualizarHogarActivo('uid3', 'hogar_abc');

      final result = await repo.obtener('uid3');
      expect(result!.hogarActivo, 'hogar_abc');
    });

    test('crearSiNoExiste no sobrescribe un usuario existente', () async {
      await repo.crear(uid: 'uid4', email: 'orig@b.cl', displayName: 'Orig');
      await repo.crearSiNoExiste(
          uid: 'uid4', email: 'new@b.cl', displayName: 'New');

      final result = await repo.obtener('uid4');
      expect(result!.email, 'orig@b.cl');
    });
  });
}
```

- [ ] **Step 3.2: Correr el test y verificar que falla**

Run: `flutter test test/features/auth/usuario_repository_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3.3: Crear `lib/features/auth/data/usuario_repository.dart`**

Write:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';

class UsuarioRepository {
  final FirebaseFirestore _db;

  UsuarioRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('usuarios');

  Future<void> crear({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final usuario = Usuario(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      plan: 'free',
      hogarActivo: null,
      createdAt: DateTime.now(),
    );
    await _col.doc(uid).set(usuario.toMap());
  }

  Future<void> crearSiNoExiste({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) {
      await crear(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl);
    }
  }

  Future<Usuario?> obtener(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return Usuario.fromFirestore(snap);
  }

  Stream<Usuario?> stream(String uid) {
    return _col.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Usuario.fromFirestore(snap);
    });
  }

  Future<void> actualizarHogarActivo(String uid, String hogarId) async {
    await _col.doc(uid).update({'hogarActivo': hogarId});
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepository(ref.watch(firestoreProvider));
});
```

- [ ] **Step 3.4: Correr el test y verificar que pasa**

Run: `flutter test test/features/auth/usuario_repository_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 3.5: Commit**

```bash
git add lib/features/auth/data/usuario_repository.dart test/features/auth/usuario_repository_test.dart
git commit -m "feat(fase-1): add UsuarioRepository with fake_cloud_firestore tests"
```

---

## Task 4: Stream de usuario y `usuarioStreamProvider`

**Files:**
- Create: `lib/features/auth/data/usuario_providers.dart`

Este provider es el que el router usará para saber si el usuario tiene hogar activo.

- [ ] **Step 4.1: Crear `lib/features/auth/data/usuario_providers.dart`**

Write:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

/// Stream del usuario autenticado como documento Firestore.
/// null = no autenticado o doc no existe aún.
/// Se usa en el router para detectar si tiene hogarActivo.
final usuarioStreamProvider = StreamProvider.autoDispose<Usuario?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final uid = authState.asData?.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(usuarioRepositoryProvider).stream(uid);
});
```

- [ ] **Step 4.2: Verificar análisis**

Run: `flutter analyze lib/features/auth/data/`
Expected: `No issues found!`

- [ ] **Step 4.3: Commit**

```bash
git add lib/features/auth/data/usuario_providers.dart
git commit -m "feat(fase-1): add usuarioStreamProvider for router guard"
```

---

## Task 5: Actualizar `AuthService` para crear documento usuario

**Files:**
- Modify: `lib/services/auth.service.dart`

Al registrar o entrar con Google, se crea el documento en Firestore si no existe.

- [ ] **Step 5.1: Actualizar `auth.service.dart`**

Write `lib/services/auth.service.dart` completo:
```dart
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
      // Garantizar que el documento existe (usuarios migrados desde versión anterior)
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

  Future<User?> signUp(
      String email, String password, {String? displayName}) async {
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
      if (e.toString().contains('user-not-found') ||
          e.toString().contains('INVALID_LOGIN_CREDENTIALS')) {
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
```

- [ ] **Step 5.2: Correr `flutter analyze`**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5.3: Correr tests existentes**

Run: `flutter test`
Expected: todos los tests previos siguen pasando (9 tests). Los tests de `LoginScreen` usan `ref.read(authServiceProvider)` en callbacks (lazy), así que no activan Firebase.

- [ ] **Step 5.4: Commit**

```bash
git add lib/services/auth.service.dart
git commit -m "feat(fase-1): AuthService creates usuario doc on sign up/in/google"
```

---

## Task 6: `RegisterScreen`

**Files:**
- Create: `lib/features/auth/presentation/register_screen.dart`
- Create: `test/features/auth/register_screen_test.dart`

- [ ] **Step 6.1: Escribir el test primero**

Write `test/features/auth/register_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/auth/presentation/register_screen.dart';

void main() {
  testWidgets('RegisterScreen muestra campos de nombre, email, contraseña y botón',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });
}
```

- [ ] **Step 6.2: Correr el test y verificar que falla**

Run: `flutter test test/features/auth/register_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 6.3: Crear `lib/features/auth/presentation/register_screen.dart`**

Write:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      // El router redirigirá automáticamente via AuthWrapper
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6.4: Correr el test y verificar que pasa**

Run: `flutter test test/features/auth/register_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6.5: Commit**

```bash
git add lib/features/auth/presentation/register_screen.dart test/features/auth/register_screen_test.dart
git commit -m "feat(fase-1): add RegisterScreen with 3-field form and test"
```

---

## Task 7: Actualizar `LoginScreen` con Google Sign-In y link a registro

**Files:**
- Modify: `lib/features/auth/presentation/login_screen.dart`

- [ ] **Step 7.1: Actualizar `login_screen.dart`**

Agregar al final de la `Column`, después del botón "Entrar como test":

```dart
// Agregar estos imports al top del archivo
// (go_router ya está importado en register_screen; aquí también se necesita)
import 'package:go_router/go_router.dart';
```

Versión completa de `lib/features/auth/presentation/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<dynamic> Function() op) async {
    setState(() { _loading = true; _error = null; });
    try {
      await op();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DespensaInteligente',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style:
                              const TextStyle(color: Colors.redAccent)),
                    ),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () => _run(() => ref
                            .read(authServiceProvider)
                            .signIn(_emailCtrl.text, _passCtrl.text)),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _run(() =>
                            ref.read(authServiceProvider).signInWithGoogle()),
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar con Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/registro'),
                    child: const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => _run(
                            ref.read(authServiceProvider).signInAsTestUser),
                    child: const Text('Entrar como test'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7.2: Actualizar el test de LoginScreen**

Actualizar `test/features/auth/login_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza campos y botones principales',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar con Google'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Entrar como test'), findsOneWidget);
  });
}
```

- [ ] **Step 7.3: Correr los tests**

Run: `flutter test test/features/auth/`
Expected: PASS (3 tests: usuario_test, login_screen_test, register_screen_test).

- [ ] **Step 7.4: Commit**

```bash
git add lib/features/auth/presentation/login_screen.dart test/features/auth/login_screen_test.dart
git commit -m "feat(fase-1): add Google Sign-In button and register link to LoginScreen"
```

---

## Task 8: Modelo `Hogar` e `Invitacion`

**Files:**
- Create: `lib/features/hogares/domain/hogar.dart`
- Create: `test/features/hogares/hogar_test.dart`

- [ ] **Step 8.1: Escribir el test primero**

```bash
mkdir -p test/features/hogares
```

Write `test/features/hogares/hogar_test.dart`:
```dart
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hogar', () {
    test('fromFirestore parsea miembros correctamente', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('hogares').doc('h1').set({
        'nombre': 'Casa Felipe',
        'creadoPor': 'uid1',
        'miembros': {'uid1': 'owner', 'uid2': 'member'},
        'miembrosIds': ['uid1', 'uid2'],
        'productosActivos': 0,
        'createdAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      });

      final snap = await firestore.collection('hogares').doc('h1').get();
      final hogar = Hogar.fromFirestore(snap);

      expect(hogar.id, 'h1');
      expect(hogar.nombre, 'Casa Felipe');
      expect(hogar.miembros['uid1'], 'owner');
      expect(hogar.miembrosIds, contains('uid2'));
    });

    test('esOwner retorna true para el creador', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('hogares').doc('h2').set({
        'nombre': 'Test',
        'creadoPor': 'uid1',
        'miembros': {'uid1': 'owner'},
        'miembrosIds': ['uid1'],
        'productosActivos': 0,
        'createdAt': 0,
      });
      final snap = await firestore.collection('hogares').doc('h2').get();
      final hogar = Hogar.fromFirestore(snap);

      expect(hogar.esOwner('uid1'), isTrue);
      expect(hogar.esOwner('uid2'), isFalse);
    });
  });

  group('Invitacion', () {
    test('estaVigente retorna false si expiró', () {
      final invitacion = Invitacion(
        codigo: 'ABC123',
        creadoPor: 'uid1',
        expiraEn: DateTime.now().subtract(const Duration(hours: 1)),
        usadoPor: null,
      );
      expect(invitacion.estaVigente, isFalse);
    });

    test('estaVigente retorna true si no expiró', () {
      final invitacion = Invitacion(
        codigo: 'XYZ789',
        creadoPor: 'uid1',
        expiraEn: DateTime.now().add(const Duration(hours: 23)),
        usadoPor: null,
      );
      expect(invitacion.estaVigente, isTrue);
    });
  });
}
```

- [ ] **Step 8.2: Correr el test y verificar que falla**

Run: `flutter test test/features/hogares/hogar_test.dart`
Expected: FAIL.

- [ ] **Step 8.3: Crear `lib/features/hogares/domain/hogar.dart`**

Write:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Hogar {
  final String id;
  final String nombre;
  final String creadoPor;
  final Map<String, String> miembros; // uid → "owner" | "member"
  final List<String> miembrosIds;
  final int productosActivos;
  final DateTime createdAt;

  const Hogar({
    required this.id,
    required this.nombre,
    required this.creadoPor,
    required this.miembros,
    required this.miembrosIds,
    required this.productosActivos,
    required this.createdAt,
  });

  bool esOwner(String uid) => miembros[uid] == 'owner';
  bool esMiembro(String uid) => miembros.containsKey(uid);

  factory Hogar.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    final rawMiembros = data['miembros'] as Map<String, dynamic>? ?? {};
    return Hogar(
      id: snap.id,
      nombre: data['nombre'] as String? ?? '',
      creadoPor: data['creadoPor'] as String? ?? '',
      miembros: rawMiembros.map((k, v) => MapEntry(k, v as String)),
      miembrosIds: List<String>.from(data['miembrosIds'] as List? ?? []),
      productosActivos: data['productosActivos'] as int? ?? 0,
      createdAt: data['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'creadoPor': creadoPor,
        'miembros': miembros,
        'miembrosIds': miembrosIds,
        'productosActivos': productosActivos,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class Invitacion {
  final String codigo;
  final String creadoPor;
  final DateTime expiraEn;
  final String? usadoPor;

  const Invitacion({
    required this.codigo,
    required this.creadoPor,
    required this.expiraEn,
    this.usadoPor,
  });

  bool get estaVigente =>
      usadoPor == null && DateTime.now().isBefore(expiraEn);

  factory Invitacion.fromFirestore(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return Invitacion(
      codigo: data['codigo'] as String? ?? snap.id,
      creadoPor: data['creadoPor'] as String? ?? '',
      expiraEn: data['expiraEn'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['expiraEn'] as int)
          : (data['expiraEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usadoPor: data['usadoPor'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'creadoPor': creadoPor,
        'expiraEn': expiraEn.millisecondsSinceEpoch,
        'usadoPor': usadoPor,
      };
}
```

- [ ] **Step 8.4: Correr el test y verificar que pasa**

Run: `flutter test test/features/hogares/hogar_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 8.5: Commit**

```bash
git add lib/features/hogares/domain/hogar.dart test/features/hogares/hogar_test.dart
git commit -m "feat(fase-1): add Hogar and Invitacion domain models with tests"
```

---

## Task 9: `HogarRepository`

**Files:**
- Create: `lib/features/hogares/data/hogar_repository.dart`
- Create: `test/features/hogares/hogar_repository_test.dart`

- [ ] **Step 9.1: Escribir los tests primero**

Write `test/features/hogares/hogar_repository_test.dart`:
```dart
import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HogarRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = HogarRepository(firestore);
  });

  group('HogarRepository', () {
    test('crear devuelve un Hogar con el creador como owner', () async {
      final hogar = await repo.crear(nombre: 'Mi Casa', ownerUid: 'uid1');

      expect(hogar.nombre, 'Mi Casa');
      expect(hogar.miembros['uid1'], 'owner');
      expect(hogar.miembrosIds, contains('uid1'));
    });

    test('listarPorUsuario retorna solo hogares del uid', () async {
      await repo.crear(nombre: 'Casa A', ownerUid: 'uid1');
      await repo.crear(nombre: 'Casa B', ownerUid: 'uid2');

      final lista = await repo.listarPorUsuario('uid1');
      expect(lista.length, 1);
      expect(lista.first.nombre, 'Casa A');
    });

    test('generarInvitacion crea una invitación vigente en la subcolección',
        () async {
      final hogar = await repo.crear(nombre: 'Casa Inv', ownerUid: 'uid1');
      final inv = await repo.generarInvitacion(hogarId: hogar.id, uid: 'uid1');

      expect(inv.codigo.length, 6);
      expect(inv.estaVigente, isTrue);

      // Verificar en firestore
      final snap = await firestore
          .collection('hogares')
          .doc(hogar.id)
          .collection('invitaciones')
          .doc(inv.codigo)
          .get();
      expect(snap.exists, isTrue);
    });

    test('unirsePorCodigo agrega al usuario como member', () async {
      final hogar = await repo.crear(nombre: 'Casa Join', ownerUid: 'uid1');
      final inv = await repo.generarInvitacion(hogarId: hogar.id, uid: 'uid1');

      await repo.unirsePorCodigo(codigo: inv.codigo, uid: 'uid2');

      final snap = await firestore.collection('hogares').doc(hogar.id).get();
      final updated = Hogar.fromFirestore(snap);
      expect(updated.miembros['uid2'], 'member');
      expect(updated.miembrosIds, contains('uid2'));
    });

    test('unirsePorCodigo lanza excepción si el código no existe', () async {
      expect(
        () => repo.unirsePorCodigo(codigo: 'XXXXXX', uid: 'uid2'),
        throwsException,
      );
    });
  });
}
```

- [ ] **Step 9.2: Correr el test y verificar que falla**

Run: `flutter test test/features/hogares/hogar_repository_test.dart`
Expected: FAIL.

- [ ] **Step 9.3: Crear `lib/features/hogares/data/hogar_repository.dart`**

Write:
```dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';

class HogarRepository {
  final FirebaseFirestore _db;

  HogarRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('hogares');

  Future<Hogar> crear({
    required String nombre,
    required String ownerUid,
  }) async {
    final ref = _col.doc();
    final hogar = Hogar(
      id: ref.id,
      nombre: nombre,
      creadoPor: ownerUid,
      miembros: {ownerUid: 'owner'},
      miembrosIds: [ownerUid],
      productosActivos: 0,
      createdAt: DateTime.now(),
    );
    await ref.set(hogar.toMap());
    return hogar;
  }

  Future<List<Hogar>> listarPorUsuario(String uid) async {
    final query = await _col
        .where('miembrosIds', arrayContains: uid)
        .get();
    return query.docs.map(Hogar.fromFirestore).toList();
  }

  Stream<List<Hogar>> streamPorUsuario(String uid) {
    return _col
        .where('miembrosIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Hogar.fromFirestore).toList());
  }

  Future<Invitacion> generarInvitacion({
    required String hogarId,
    required String uid,
  }) async {
    final codigo = _generarCodigo();
    final invitacion = Invitacion(
      codigo: codigo,
      creadoPor: uid,
      expiraEn: DateTime.now().add(const Duration(hours: 24)),
      usadoPor: null,
    );
    await _col
        .doc(hogarId)
        .collection('invitaciones')
        .doc(codigo)
        .set(invitacion.toMap());
    return invitacion;
  }

  /// Busca el código en todos los hogares (colección group query).
  Future<void> unirsePorCodigo({
    required String codigo,
    required String uid,
  }) async {
    // Buscar la invitación en todos los hogares via collectionGroup
    final query = await _db
        .collectionGroup('invitaciones')
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Código de invitación no encontrado');
    }

    final invSnap = query.docs.first;
    final invitacion = Invitacion.fromFirestore(invSnap);

    if (!invitacion.estaVigente) {
      throw Exception('El código ha expirado o ya fue usado');
    }

    // El hogarId es el padre del padre (hogares/{hogarId}/invitaciones/{codigo})
    final hogarId = invSnap.reference.parent.parent!.id;

    await _db.runTransaction((tx) async {
      final hogarRef = _col.doc(hogarId);
      tx.update(hogarRef, {
        'miembros.$uid': 'member',
        'miembrosIds': FieldValue.arrayUnion([uid]),
      });
      tx.update(invSnap.reference, {'usadoPor': uid});
    });
  }

  String _generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

final hogarRepositoryProvider = Provider<HogarRepository>((ref) {
  return HogarRepository(ref.watch(firestoreProvider));
});
```

- [ ] **Step 9.4: Correr el test y verificar que pasa**

Run: `flutter test test/features/hogares/hogar_repository_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 9.5: Correr toda la suite**

Run: `flutter test`
Expected: todos los tests previos + los nuevos pasan.

- [ ] **Step 9.6: Commit**

```bash
git add lib/features/hogares/data/hogar_repository.dart test/features/hogares/hogar_repository_test.dart
git commit -m "feat(fase-1): add HogarRepository with invite code logic and 5 tests"
```

---

## Task 10: `OnboardingHogarScreen`

**Files:**
- Create: `lib/features/hogares/presentation/onboarding_hogar_screen.dart`
- Create: `test/features/hogares/onboarding_hogar_screen_test.dart`

Esta pantalla aparece cuando el usuario no tiene hogar. Tiene un campo para el nombre + botón "Crear mi hogar".

- [ ] **Step 10.1: Escribir el test primero**

Write `test/features/hogares/onboarding_hogar_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/hogares/presentation/onboarding_hogar_screen.dart';

void main() {
  testWidgets('OnboardingHogarScreen muestra campo de nombre y botón',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingHogarScreen()),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Crear mi hogar'), findsOneWidget);
  });
}
```

- [ ] **Step 10.2: Correr el test y verificar que falla**

Run: `flutter test test/features/hogares/onboarding_hogar_screen_test.dart`
Expected: FAIL.

- [ ] **Step 10.3: Crear `lib/features/hogares/presentation/onboarding_hogar_screen.dart`**

Write:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class OnboardingHogarScreen extends ConsumerStatefulWidget {
  const OnboardingHogarScreen({super.key});

  @override
  ConsumerState<OnboardingHogarScreen> createState() =>
      _OnboardingHogarScreenState();
}

class _OnboardingHogarScreenState
    extends ConsumerState<OnboardingHogarScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _nameCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa un nombre para tu hogar');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final uid =
          ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
      final hogar = await ref
          .read(hogarRepositoryProvider)
          .crear(nombre: nombre, ownerUid: uid);
      await ref
          .read(usuarioRepositoryProvider)
          .actualizarHogarActivo(uid, hogar.id);
      // El router redirigirá automáticamente al detectar hogarActivo
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Bienvenido!',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Crea tu primer hogar para empezar a gestionar tu despensa.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nombre del hogar'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _crear,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Crear mi hogar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 10.4: Correr el test y verificar que pasa**

Run: `flutter test test/features/hogares/onboarding_hogar_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 10.5: Commit**

```bash
git add lib/features/hogares/presentation/onboarding_hogar_screen.dart test/features/hogares/onboarding_hogar_screen_test.dart
git commit -m "feat(fase-1): add OnboardingHogarScreen with test"
```

---

## Task 11: `MisHogaresScreen`

**Files:**
- Create: `lib/features/hogares/presentation/mis_hogares_screen.dart`

Esta pantalla lista los hogares del usuario, muestra el código de invitación del activo, y tiene un campo para unirse por código.

- [ ] **Step 11.1: Crear `lib/features/hogares/presentation/mis_hogares_screen.dart`**

Write:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

final _hogaresStreamProvider =
    StreamProvider.autoDispose<List<Hogar>>((ref) {
  final uid =
      ref.watch(firebaseAuthStateProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(hogarRepositoryProvider).streamPorUsuario(uid);
});

class MisHogaresScreen extends ConsumerStatefulWidget {
  const MisHogaresScreen({super.key});

  @override
  ConsumerState<MisHogaresScreen> createState() => _MisHogaresScreenState();
}

class _MisHogaresScreenState extends ConsumerState<MisHogaresScreen> {
  final _codigoCtrl = TextEditingController();
  final _nuevoNombreCtrl = TextEditingController();
  String? _invitacionActual;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nuevoNombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearHogar() async {
    final nombre = _nuevoNombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final uid =
          ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
      final hogar = await ref
          .read(hogarRepositoryProvider)
          .crear(nombre: nombre, ownerUid: uid);
      await ref
          .read(usuarioRepositoryProvider)
          .actualizarHogarActivo(uid, hogar.id);
      _nuevoNombreCtrl.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unirse() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    if (codigo.length != 6) {
      setState(() => _error = 'El código debe tener 6 caracteres');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final uid =
          ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
      await ref
          .read(hogarRepositoryProvider)
          .unirsePorCodigo(codigo: codigo, uid: uid);
      _codigoCtrl.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generarInvitacion(String hogarId) async {
    final uid =
        ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
    final inv = await ref
        .read(hogarRepositoryProvider)
        .generarInvitacion(hogarId: hogarId, uid: uid);
    setState(() => _invitacionActual = inv.codigo);
  }

  Future<void> _seleccionarHogar(String hogarId) async {
    final uid =
        ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
    await ref
        .read(usuarioRepositoryProvider)
        .actualizarHogarActivo(uid, hogarId);
  }

  @override
  Widget build(BuildContext context) {
    final hogaresAsync = ref.watch(_hogaresStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis hogares')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: hogaresAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (hogares) => hogares.isEmpty
                    ? const Center(child: Text('No perteneces a ningún hogar'))
                    : ListView.builder(
                        itemCount: hogares.length,
                        itemBuilder: (_, i) {
                          final h = hogares[i];
                          return Card(
                            child: ListTile(
                              title: Text(h.nombre),
                              subtitle: Text(
                                  '${h.miembrosIds.length} miembro(s)'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    tooltip: 'Generar código de invitación',
                                    onPressed: () =>
                                        _generarInvitacion(h.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline),
                                    tooltip: 'Seleccionar como activo',
                                    onPressed: () =>
                                        _seleccionarHogar(h.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (_invitacionActual != null)
              Card(
                color: Colors.amber.shade900,
                child: ListTile(
                  title: Text(
                    'Código de invitación: $_invitacionActual',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  subtitle: const Text('Válido por 24 horas'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _invitacionActual!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Código copiado al portapapeles')),
                      );
                    },
                  ),
                ),
              ),
            const Divider(),
            // Unirse por código
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Código de invitación'),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _unirse,
                  child: const Text('Unirme'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Crear hogar nuevo
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevoNombreCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nuevo hogar'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _crearHogar,
                  child: const Text('Crear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 11.2: Verificar análisis**

Run: `flutter analyze lib/features/hogares/`
Expected: `No issues found!`

- [ ] **Step 11.3: Commit**

```bash
git add lib/features/hogares/presentation/mis_hogares_screen.dart
git commit -m "feat(fase-1): add MisHogaresScreen with list, invite code and join"
```

---

## Task 12: Actualizar router con `hasHogar` y nuevas rutas

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `test/app/router_test.dart`
- Modify: `lib/main.dart`

- [ ] **Step 12.1: Actualizar los tests del router primero**

Write `test/app/router_test.dart`:
```dart
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
```

- [ ] **Step 12.2: Correr el test y verificar que falla**

Run: `flutter test test/app/router_test.dart`
Expected: FAIL — `calculateRedirect` no acepta `hasHogar`.

- [ ] **Step 12.3: Actualizar `lib/app/router.dart`**

Write:
```dart
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
```

- [ ] **Step 12.4: Correr el test y verificar que pasa**

Run: `flutter test test/app/router_test.dart`
Expected: PASS (10 tests).

- [ ] **Step 12.5: Actualizar `lib/main.dart` para pasar `hasHogar`**

Write `lib/main.dart`:
```dart
import 'package:despensa_inteligente/app/router.dart';
import 'package:despensa_inteligente/app/theme.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/services/auth.service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: DespensaInteligenteApp()));
}

class DespensaInteligenteApp extends ConsumerWidget {
  const DespensaInteligenteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthStateProvider);
    final usuarioAsync = ref.watch(usuarioStreamProvider);

    final router = buildRouter(
      isLoggedIn: () => authState.asData?.value != null,
      hasHogar: () {
        if (usuarioAsync.isLoading) return null;
        return usuarioAsync.asData?.value?.hogarActivo != null;
      },
    );

    return MaterialApp.router(
      title: 'DespensaInteligente',
      theme: DespensaTheme.dark(),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 12.6: Correr `flutter analyze` + suite completa**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` + todos los tests pasan.

- [ ] **Step 12.7: Commit**

```bash
git add lib/app/router.dart lib/main.dart test/app/router_test.dart
git commit -m "feat(fase-1): update router with hasHogar guard and new routes (10 tests)"
```

---

## Task 13: Actualizar `DashboardScreen` con info del hogar

**Files:**
- Modify: `lib/features/home/presentation/dashboard_screen.dart`

- [ ] **Step 13.1: Actualizar `dashboard_screen.dart`**

Write:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final nombre = usuarioAsync.asData?.value?.displayName ?? '';
    final hogar = usuarioAsync.asData?.value?.hogarActivo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DespensaInteligente'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Mis hogares',
            onPressed: () => context.push('/hogares'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nombre.isNotEmpty ? '¡Hola, $nombre! 👋' : 'Bienvenido 👋',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            if (hogar != null)
              Text(
                'Hogar activo: $hogar',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 13.2: Actualizar el test del dashboard (ya no usa MaterialApp puro)**

Actualizar `test/features/home/dashboard_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen muestra título y botón cerrar sesión',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump(); // Permite que el stream emita

    expect(find.text('DespensaInteligente'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
```

- [ ] **Step 13.3: Correr los tests**

Run: `flutter test test/features/home/`
Expected: PASS.

- [ ] **Step 13.4: Commit**

```bash
git add lib/features/home/presentation/dashboard_screen.dart test/features/home/dashboard_screen_test.dart
git commit -m "feat(fase-1): DashboardScreen shows hogar name and mis hogares link"
```

---

## Task 14: Reglas Firestore multitenant

**Files:**
- Modify: `firestore.rules`

- [ ] **Step 14.1: Actualizar `firestore.rules`**

Write:
```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Helpers
    function isAuth() {
      return request.auth != null;
    }

    function isMember(hogarId) {
      return isAuth() &&
        request.auth.uid in get(/databases/$(database)/documents/hogares/$(hogarId)).data.miembrosIds;
    }

    function isOwner(hogarId) {
      return isAuth() &&
        get(/databases/$(database)/documents/hogares/$(hogarId)).data.miembros[request.auth.uid] == 'owner';
    }

    // Usuarios: solo el propio usuario lee y escribe su documento
    match /usuarios/{uid} {
      allow read, write: if isAuth() && request.auth.uid == uid;
    }

    // Hogares: legibles por miembros, editables por owners (datos base)
    match /hogares/{hogarId} {
      allow read: if isMember(hogarId);
      allow create: if isAuth() &&
        request.resource.data.creadoPor == request.auth.uid &&
        request.auth.uid in request.resource.data.miembrosIds;
      allow update: if isOwner(hogarId);
      allow delete: if isOwner(hogarId);

      // Invitaciones: miembros pueden leer, owners pueden crear
      match /invitaciones/{codigo} {
        allow read: if isMember(hogarId);
        allow create: if isOwner(hogarId);
        // Actualizar (marcar como usada) es privilegiado; lo hace el backend vía Functions en prod.
        // Para el MVP (sin Functions de escritura), se permite desde cliente autenticado:
        allow update: if isAuth();
      }

      // Despensa: miembros del hogar pueden leer y escribir
      match /despensa/{itemId} {
        allow read, write: if isMember(hogarId);
      }
    }

    // Productos globales: lectura autenticada, escritura solo desde Functions (admin SDK)
    match /productos_globales/{barcode} {
      allow read: if isAuth();
      allow write: if false; // solo Firebase Admin SDK (Functions)
    }

    // planes_config: lectura autenticada, escritura solo admin
    match /planes_config/{planId} {
      allow read: if isAuth();
      allow write: if false;
    }

    // Deny-all por defecto para todo lo demás
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 14.2: Validar JSON/sintaxis**

Run: `cat firestore.rules | head -5`
Expected: muestra el inicio del archivo (validación visual de que existe y tiene contenido).

*Nota:* La validación completa de reglas requiere el emulador (`firebase emulators:exec`). Se deja como paso de verificación manual o para el CI de Fase 6.

- [ ] **Step 14.3: Commit**

```bash
git add firestore.rules
git commit -m "feat(fase-1): add multitenant Firestore security rules"
```

---

## Task 15: Validación final + update del plan maestro

**Files:**
- Modify: `PLAN_IMPLEMENTACION.md`

- [ ] **Step 15.1: Correr `flutter analyze` completo**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 15.2: Correr suite completa de tests**

Run: `flutter test`
Expected: todos los tests pasan. Conteo esperado: ~24+ tests (9 de Fase 0 + los nuevos de Fase 1).

- [ ] **Step 15.3: Correr `flutter build web --release`**

Run: `flutter build web --release 2>&1 | tail -3`
Expected: `✓ Built build/web`

- [ ] **Step 15.4: Marcar Fase 1 como completada en `PLAN_IMPLEMENTACION.md`**

Cambiar los `- [ ] 1.X` a `- [x] 1.X` en el archivo.

- [ ] **Step 15.5: Commit final**

```bash
git add PLAN_IMPLEMENTACION.md
git commit -m "docs(fase-1): mark Fase 1 complete in master plan"
```

---

## Criterio de salida de la Fase 1

✓ `flutter analyze` verde.
✓ `flutter test` verde con ≥ 24 tests.
✓ `flutter build web --release` sin errores.
✓ Usuario puede registrarse por email o clic en "Entrar con Google".
✓ Al registrarse se crea `/usuarios/{uid}` con `plan: "free"`.
✓ Sin hogar → redirige a `/onboarding/hogar`.
✓ Puede crear un hogar y queda como owner.
✓ Puede generar un código de 6 caracteres.
✓ Un segundo usuario puede unirse al mismo hogar con ese código.
✓ Ambos ven el dashboard mostrando el nombre del hogar.
✓ Reglas Firestore: deny-all para cruzar hogares, escritura de productos_globales solo desde admin.

---

## Notas para el ejecutor

1. **Google Sign-In** requiere que el usuario haya configurado el proveedor en Firebase Console. Si no está habilitado, el botón lanzará un error controlado que se muestra en pantalla. La app no rompe.
2. **TDD disciplinado**: cada task escribe el test primero, verifica que falla, luego implementa. No saltarse este paso.
3. **Commit por task**: no mezclar cambios de tasks distintas en un mismo commit.
4. **Cambio de modelo**: esta fase tiene lógica de dominio no trivial (invitaciones, guards, Firestore rules). Si algo no cuadra con el spec, escalar a Opus antes de continuar.
5. **Tests de reglas Firestore**: la validación completa de reglas multitenant requiere el emulador. Los unit tests de los repositorios usan `fake_cloud_firestore` que no aplica las reglas. La verificación de reglas es manual con el emulador o se automatiza en Fase 6 via CI.
