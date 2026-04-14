# Fase 0 — Fundaciones & Tooling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar el repositorio compilable (`flutter analyze` verde, `flutter run -d chrome` muestra login funcional que redirige a un dashboard placeholder) y con la infraestructura de trabajo lista: router, tema extraído, estructura de carpetas `features/*`, Cloud Functions TS scaffoldeado, reglas Firestore base, CI en GitHub Actions, y dos skills locales (`despensa:flutter-ops`, `despensa:firebase-ops`) para que Claude pueda operar Flutter y Firebase sin intervención manual.

**Architecture:** Partimos de un scaffold roto (`main.dart` referencia un `DashboardScreen` inexistente, `login_screen.dart` vacío, `firestore_service.dart` y `recipe_service.dart` vacíos). Esta fase reconstruye la capa mínima: `main.dart` → `app/router.dart` (go_router con guard de auth via `firebaseAuthStateProvider`) → features `auth/` y `home/` con pantallas mínimas. En paralelo se agrega `functions/` como proyecto TypeScript con una Function `healthcheck` trivial, `firestore.rules` y `firestore.indexes.json` base, y un workflow CI que corre `flutter analyze` + `flutter test` + `flutter build web` + `npm run build` en `functions/`.

**Tech Stack:** Flutter 3.22+, Dart 3.9, `flutter_riverpod` 3, `go_router` 16, `firebase_core`/`firebase_auth`/`cloud_firestore`, Cloud Functions 2ª gen en Node 20 + TypeScript 5, GitHub Actions, Firebase CLI.

**Prerequisitos manuales del operador humano** (el agente no los ejecuta porque requieren login interactivo o toca cuentas externas):
1. `firebase login` ya hecho con una cuenta con acceso a `despensa-inteligente-c1f9d`.
2. `flutter --version` imprime 3.22 o superior.
3. `node --version` imprime v20.x.
4. Se permite ejecutar `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web`, `npm install`, `npm run build` en este repo.

Si alguno falla, detenerse e informar al usuario antes de seguir.

---

## File Structure

**Archivos creados o modificados en esta fase:**

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `lib/main.dart` | Modificar | Bootstrap: Firebase init + `ProviderScope` + `MaterialApp.router` |
| `lib/app/router.dart` | Crear | Config de `go_router` + guard de auth |
| `lib/app/theme.dart` | Crear | Tema dark + accent `#cde600`, extraído de `main.dart` |
| `lib/features/auth/presentation/login_screen.dart` | Sobrescribir | Pantalla de login mínima con email/password + botón test |
| `lib/features/home/presentation/dashboard_screen.dart` | Crear | Placeholder con botón "Cerrar sesión" |
| `lib/features/{despensa,recetas,hogares,plan,productos_globales,scanner}/{data,domain,presentation}/.gitkeep` | Crear | Esqueleto de carpetas para fases futuras |
| `lib/services/firestore_service.dart` | Borrar | Archivo vacío sin uso |
| `lib/services/recipe_service.dart` | Borrar | Archivo vacío sin uso |
| `test/widget_test.dart` | Sobrescribir | Reemplazar el counter test por un smoke test real |
| `test/features/auth/login_screen_test.dart` | Crear | Widget test del login |
| `test/features/home/dashboard_screen_test.dart` | Crear | Widget test del dashboard |
| `test/app/router_test.dart` | Crear | Test de la config de rutas (sin Firebase) |
| `firebase.json` | Modificar | Agregar `hosting`, `functions`, `firestore` preservando el bloque `flutter` existente |
| `firestore.rules` | Crear | Regla base: deny-all en prod, abierto en emulator |
| `firestore.indexes.json` | Crear | JSON vacío con array `indexes` y `fieldOverrides` |
| `functions/package.json` | Crear | Scripts `build`, `serve`, `deploy`, dependencias |
| `functions/tsconfig.json` | Crear | Target ES2020, strict, outDir `lib` |
| `functions/src/index.ts` | Crear | Function `healthcheck` trivial |
| `functions/.eslintrc.js` | Crear | Config ESLint + TypeScript |
| `functions/.gitignore` | Crear | Ignora `lib/`, `node_modules/` |
| `.github/workflows/ci.yml` | Crear | CI: flutter analyze/test/build web + functions build |
| `.claude/skills/despensa-flutter-ops/SKILL.md` | Crear | Skill para operaciones Flutter (analyze/test/build) |
| `.claude/skills/despensa-firebase-ops/SKILL.md` | Crear | Skill para operaciones Firebase (emulators/deploy) |
| `PLAN_IMPLEMENTACION.md` | Modificar | Marcar checklist de Fase 0 como completada al final |

**Notas:**
- `lib/services/auth.service.dart` se deja tal cual. Es el único archivo funcional del código actual.
- `lib/firebase_options.dart` nunca se toca (es autogenerado).
- La carpeta `features/auth/presentation/` ya existe; solo se sobrescribe `login_screen.dart`.

---

## Task 1: Baseline y limpieza de archivos vacíos

**Files:**
- Delete: `lib/services/firestore_service.dart`
- Delete: `lib/services/recipe_service.dart`

- [ ] **Step 1.1: Verificar estado inicial del repo**

Run:
```bash
cd /Users/felipenavarretenavarrete/Desktop/proyectosWebiados/despensa_inteligente
git status
flutter pub get
```

Expected: `git status` limpio (nada pendiente); `flutter pub get` termina sin errores (descarga paquetes).

- [ ] **Step 1.2: Ejecutar `flutter analyze` para capturar el error baseline**

Run: `flutter analyze`
Expected: FAIL. Debe mencionar que `DashboardScreen` no está definido en `lib/main.dart`. Anotar la línea exacta para compararla al final de la fase.

- [ ] **Step 1.3: Borrar los dos archivos de servicios vacíos**

Run:
```bash
rm lib/services/firestore_service.dart
rm lib/services/recipe_service.dart
```

Razón: ambos contienen solo 1 línea (`// TODO Implement this library.`) y se reconstruirán en fases posteriores con su contenido real.

- [ ] **Step 1.4: Commit**

```bash
git add -A
git commit -m "chore(fase-0): remove empty service stubs"
```

---

## Task 2: Extraer tema a `lib/app/theme.dart`

**Files:**
- Create: `lib/app/theme.dart`
- Modify: `lib/main.dart`

- [ ] **Step 2.1: Crear `lib/app/theme.dart`**

Write:
```dart
import 'package:flutter/material.dart';

class DespensaTheme {
  static const Color accent = Color(0xffcde600);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: accent,
      fontFamily: 'Bricolage Grotesque',
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.black,
        surface: Colors.black,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2.2: Verificar que compila**

Run: `flutter analyze lib/app/theme.dart`
Expected: `No issues found!` (o la firma "No issues" equivalente). Si aparece error de font family, está OK por ahora — es solo un warning porque no tenemos los .ttf aún.

---

## Task 3: Crear `DashboardScreen` placeholder

**Files:**
- Create: `lib/features/home/presentation/dashboard_screen.dart`
- Create: `test/features/home/dashboard_screen_test.dart`

- [ ] **Step 3.1: Escribir el widget test (falla primero)**

Write `test/features/home/dashboard_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen muestra título y botón cerrar sesión',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardScreen()),
    );

    expect(find.text('DespensaInteligente'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
```

- [ ] **Step 3.2: Correr el test y ver que falla**

Run: `flutter test test/features/home/dashboard_screen_test.dart`
Expected: FAIL con mensaje `Target of URI doesn't exist: 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart'`.

- [ ] **Step 3.3: Crear `DashboardScreen`**

Write `lib/features/home/presentation/dashboard_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DespensaInteligente'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido 👋',
              style: TextStyle(fontSize: 24),
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

*Nota:* El widget es `ConsumerWidget`, pero en el test lo usamos sin `ProviderScope`. Funciona porque solo llamamos `ref.read` en `onPressed` (lazy). Si el test empieza a tocar el botón, habrá que envolverlo en `ProviderScope` — de momento no.

- [ ] **Step 3.4: Correr el test y ver que pasa**

Run: `flutter test test/features/home/dashboard_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 3.5: Commit**

```bash
git add lib/app/theme.dart lib/features/home/presentation/dashboard_screen.dart test/features/home/dashboard_screen_test.dart
git commit -m "feat(fase-0): extract theme and add dashboard placeholder"
```

---

## Task 4: Reescribir `LoginScreen`

**Files:**
- Overwrite: `lib/features/auth/presentation/login_screen.dart`
- Create: `test/features/auth/login_screen_test.dart`

- [ ] **Step 4.1: Escribir el widget test primero**

Write `test/features/auth/login_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza campos y botones', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Entrar como test'), findsOneWidget);
  });
}
```

- [ ] **Step 4.2: Correr el test y ver que falla**

Run: `flutter test test/features/auth/login_screen_test.dart`
Expected: FAIL (el archivo existe pero no exporta `LoginScreen` — solo tiene el TODO).

- [ ] **Step 4.3: Sobrescribir `login_screen.dart`**

Write `lib/features/auth/presentation/login_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    setState(() {
      _loading = true;
      _error = null;
    });
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
    final auth = ref.read(authServiceProvider);

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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () => _run(
                              () => auth.signIn(_emailCtrl.text, _passCtrl.text),
                            ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => _run(
                              () => auth.signUp(_emailCtrl.text, _passCtrl.text),
                            ),
                    child: const Text('Crear cuenta'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : () => _run(auth.signInAsTestUser),
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

- [ ] **Step 4.4: Correr el test y ver que pasa**

Run: `flutter test test/features/auth/login_screen_test.dart`
Expected: PASS (1 test).

- [ ] **Step 4.5: Commit**

```bash
git add lib/features/auth/presentation/login_screen.dart test/features/auth/login_screen_test.dart
git commit -m "feat(fase-0): implement minimal LoginScreen with test"
```

---

## Task 5: Router con `go_router`

**Files:**
- Create: `lib/app/router.dart`
- Create: `test/app/router_test.dart`

- [ ] **Step 5.1: Escribir el test del router**

Write `test/app/router_test.dart`:
```dart
import 'package:despensa_inteligente/app/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('buildRouter', () {
    test('tiene las rutas principales registradas', () {
      final router = buildRouter(isLoggedIn: () => false);
      final paths = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();

      expect(paths, containsAll(<String>['/login', '/']));
    });

    test('redirige a /login cuando no hay sesión', () {
      final router = buildRouter(isLoggedIn: () => false);
      final redirect = router.configuration.redirect;
      final result = redirect(
        _FakeBuildContext(),
        _FakeGoRouterState(fullPath: '/'),
      );
      expect(result, '/login');
    });

    test('redirige a / cuando hay sesión y el usuario entra en /login', () {
      final router = buildRouter(isLoggedIn: () => true);
      final redirect = router.configuration.redirect;
      final result = redirect(
        _FakeBuildContext(),
        _FakeGoRouterState(fullPath: '/login'),
      );
      expect(result, '/');
    });
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}
class _FakeGoRouterState extends Fake implements GoRouterState {
  _FakeGoRouterState({required this.fullPath});
  @override
  final String? fullPath;
  @override
  String get matchedLocation => fullPath ?? '/';
}
```

*Nota:* Necesitamos `import 'package:flutter/widgets.dart' show BuildContext;`. Agregar al top del test si falla por eso.

- [ ] **Step 5.2: Correr el test y ver que falla**

Run: `flutter test test/app/router_test.dart`
Expected: FAIL porque `package:despensa_inteligente/app/router.dart` no existe.

- [ ] **Step 5.3: Crear `lib/app/router.dart`**

Write:
```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';

typedef IsLoggedIn = bool Function();

GoRouter buildRouter({required IsLoggedIn isLoggedIn}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final logged = isLoggedIn();
      final goingToLogin = state.matchedLocation == '/login';

      if (!logged && !goingToLogin) return '/login';
      if (logged && goingToLogin) return '/';
      return null;
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
```

- [ ] **Step 5.4: Correr el test y ver que pasa**

Run: `flutter test test/app/router_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5.5: Commit**

```bash
git add lib/app/router.dart test/app/router_test.dart
git commit -m "feat(fase-0): add go_router config with auth guard"
```

---

## Task 6: Conectar `main.dart` al router

**Files:**
- Modify: `lib/main.dart`
- Overwrite: `test/widget_test.dart`

- [ ] **Step 6.1: Sobrescribir `test/widget_test.dart`** para que deje de depender del counter test (que va a romperse cuando cambiemos `main.dart`).

Write:
```dart
import 'package:despensa_inteligente/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Theme dark expone el accent #cde600', (tester) async {
    final theme = DespensaTheme.dark();
    expect(theme.colorScheme.primary, DespensaTheme.accent);
    expect(theme.scaffoldBackgroundColor, Colors.black);
  });
}
```

- [ ] **Step 6.2: Sobrescribir `lib/main.dart`**

Write:
```dart
import 'package:despensa_inteligente/app/router.dart';
import 'package:despensa_inteligente/app/theme.dart';
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

    final router = buildRouter(
      isLoggedIn: () => authState.asData?.value != null,
    );

    return MaterialApp.router(
      title: 'DespensaInteligente',
      theme: DespensaTheme.dark(),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 6.3: Correr `flutter analyze`**

Run: `flutter analyze`
Expected: `No issues found!`. Si aparece un warning por `authState` no usado directamente (porque lo pasamos a un closure), ignorarlo o refactorizar.

- [ ] **Step 6.4: Correr toda la suite de tests**

Run: `flutter test`
Expected: PASS en todos los tests (4 archivos: widget_test, login, dashboard, router).

- [ ] **Step 6.5: Commit**

```bash
git add lib/main.dart test/widget_test.dart
git commit -m "feat(fase-0): wire main.dart to router with auth guard"
```

---

## Task 7: Esqueleto de carpetas `features/*`

**Files:**
- Create: 18 archivos `.gitkeep` para el esqueleto

- [ ] **Step 7.1: Crear la estructura de carpetas**

Run:
```bash
mkdir -p \
  lib/features/despensa/data lib/features/despensa/domain lib/features/despensa/presentation \
  lib/features/recetas/data lib/features/recetas/domain lib/features/recetas/presentation \
  lib/features/hogares/data lib/features/hogares/domain lib/features/hogares/presentation \
  lib/features/plan/data lib/features/plan/domain lib/features/plan/presentation \
  lib/features/productos_globales/data lib/features/productos_globales/domain lib/features/productos_globales/presentation \
  lib/features/scanner/data lib/features/scanner/presentation \
  lib/core/errors lib/core/extensions \
  lib/shared/widgets
```

- [ ] **Step 7.2: Poblar con `.gitkeep`**

Run:
```bash
find lib/features lib/core lib/shared -type d -empty -exec touch {}/.gitkeep \;
```

- [ ] **Step 7.3: Verificar con git**

Run: `git status`
Expected: ~18 archivos `.gitkeep` nuevos listados como untracked.

- [ ] **Step 7.4: Commit**

```bash
git add lib/features lib/core lib/shared
git commit -m "chore(fase-0): scaffold feature folders"
```

---

## Task 8: Reglas e índices Firestore base

**Files:**
- Create: `firestore.rules`
- Create: `firestore.indexes.json`

- [ ] **Step 8.1: Crear `firestore.rules`**

Write:
```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Base de Fase 0: todo negado por defecto.
    // Las fases 1+ agregan reglas por colección.
    // En el emulador las reglas se pueden sobrescribir temporalmente
    // para desarrollo local.

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- [ ] **Step 8.2: Crear `firestore.indexes.json`**

Write:
```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

- [ ] **Step 8.3: Commit**

```bash
git add firestore.rules firestore.indexes.json
git commit -m "chore(fase-0): add firestore rules and indexes baseline"
```

---

## Task 9: Ampliar `firebase.json` con hosting, functions y firestore

**Files:**
- Modify: `firebase.json`

- [ ] **Step 9.1: Leer el `firebase.json` actual y memorizar su contenido**

Run: `cat firebase.json`
Expected: Un JSON con la clave top-level `"flutter": {...}` generado por `flutterfire configure`. **NO borrar esa clave.**

- [ ] **Step 9.2: Sobrescribir `firebase.json` con el contenido fusionado**

Write:
```json
{
  "flutter": {
    "platforms": {
      "android": {
        "default": {
          "projectId": "despensa-inteligente-c1f9d",
          "appId": "1:855995089769:android:4e16cb687e58423abeb3f8",
          "fileOutput": "android/app/google-services.json"
        }
      },
      "ios": {
        "default": {
          "projectId": "despensa-inteligente-c1f9d",
          "appId": "1:855995089769:ios:834b8b7f20d01b0cbeb3f8",
          "uploadDebugSymbols": false,
          "fileOutput": "ios/Runner/GoogleService-Info.plist"
        }
      },
      "dart": {
        "lib/firebase_options.dart": {
          "projectId": "despensa-inteligente-c1f9d",
          "configurations": {
            "android": "1:855995089769:android:4e16cb687e58423abeb3f8",
            "ios": "1:855995089769:ios:834b8b7f20d01b0cbeb3f8",
            "web": "1:855995089769:web:27e6445ca124eefabeb3f8"
          }
        }
      }
    }
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "runtime": "nodejs20",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ],
      "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
    }
  ],
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  },
  "emulators": {
    "auth": { "port": 9099 },
    "functions": { "port": 5001 },
    "firestore": { "port": 8080 },
    "hosting": { "port": 5000 },
    "ui": { "enabled": true },
    "singleProjectMode": true
  }
}
```

- [ ] **Step 9.3: Validar que sigue siendo JSON válido**

Run: `python3 -c "import json; json.load(open('firebase.json'))"`
Expected: sin output (éxito silencioso).

- [ ] **Step 9.4: Commit**

```bash
git add firebase.json
git commit -m "chore(fase-0): expand firebase.json with hosting/functions/firestore"
```

---

## Task 10: Scaffold de Cloud Functions en TypeScript

**Files:**
- Create: `functions/package.json`
- Create: `functions/tsconfig.json`
- Create: `functions/.eslintrc.js`
- Create: `functions/.gitignore`
- Create: `functions/src/index.ts`

- [ ] **Step 10.1: Crear `functions/package.json`**

Write:
```json
{
  "name": "functions",
  "version": "0.1.0",
  "private": true,
  "description": "Cloud Functions para DespensaInteligente",
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "build": "tsc",
    "build:watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "test": "echo \"no tests yet\" && exit 0"
  },
  "engines": {
    "node": "20"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^12.1.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "eslint": "^8.57.0",
    "eslint-config-google": "^0.14.0",
    "typescript": "^5.4.0"
  }
}
```

- [ ] **Step 10.2: Crear `functions/tsconfig.json`**

Write:
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2020",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

- [ ] **Step 10.3: Crear `functions/.eslintrc.js`**

Write:
```js
module.exports = {
  root: true,
  env: { es2020: true, node: true },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "google",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
  },
  ignorePatterns: ["/lib/**/*", "node_modules/**/*"],
  plugins: ["@typescript-eslint"],
  rules: {
    quotes: ["error", "double"],
    "import/no-unresolved": 0,
    indent: ["error", 2],
    "object-curly-spacing": ["error", "always"],
    "max-len": ["error", { code: 120 }],
    "require-jsdoc": 0,
    "valid-jsdoc": 0,
  },
};
```

- [ ] **Step 10.4: Crear `functions/.gitignore`**

Write:
```
node_modules/
lib/
*.log
.env
.runtimeconfig.json
```

- [ ] **Step 10.5: Crear `functions/src/index.ts` con la function `healthcheck`**

Write:
```ts
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export const healthcheck = onRequest((_request, response) => {
  logger.info("healthcheck invoked");
  response.json({
    ok: true,
    service: "despensa-inteligente-functions",
    timestamp: new Date().toISOString(),
  });
});
```

- [ ] **Step 10.6: Instalar dependencias y compilar**

Run:
```bash
cd functions
npm install
npm run build
cd ..
```

Expected: `npm install` termina sin errores (puede tardar 1–2 min). `npm run build` genera `functions/lib/index.js` sin errores.

Si `npm install` falla por red o versiones, reintentar una vez; si sigue fallando, detenerse y reportar.

- [ ] **Step 10.7: Commit**

```bash
git add functions/package.json functions/tsconfig.json functions/.eslintrc.js functions/.gitignore functions/src/index.ts functions/package-lock.json
git commit -m "feat(fase-0): scaffold cloud functions with TS and healthcheck"
```

*Nota:* no se commitea `functions/node_modules/` ni `functions/lib/` — ambos están en `.gitignore`.

---

## Task 11: CI en GitHub Actions

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 11.1: Crear el workflow**

Write `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  flutter:
    name: Flutter (analyze + test + build web)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.24.x'
          cache: true

      - name: Pub get
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test

      - name: Build web
        run: flutter build web --release

  functions:
    name: Cloud Functions (build)
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: functions
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: functions/package-lock.json

      - name: Install
        run: npm ci

      - name: Build
        run: npm run build
```

- [ ] **Step 11.2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci(fase-0): add flutter + functions GitHub Actions workflow"
```

*Nota:* el workflow no se ejecuta localmente. Se valida al hacer push o crear el PR. No bloquear la fase por esto.

---

## Task 12: Skill `despensa:flutter-ops`

**Files:**
- Create: `.claude/skills/despensa-flutter-ops/SKILL.md`

- [ ] **Step 12.1: Crear directorio y skill**

Run: `mkdir -p .claude/skills/despensa-flutter-ops`

Write `.claude/skills/despensa-flutter-ops/SKILL.md`:
```markdown
---
name: despensa-flutter-ops
description: Operaciones de desarrollo Flutter para DespensaInteligente — analyze, test, build web, build apk. Úsalo cada vez que necesites validar código Flutter antes de commitear, o preparar un build.
---

# despensa-flutter-ops

Skill interno del proyecto DespensaInteligente para operar la CLI de Flutter de forma consistente.

## Cuándo usar este skill

- Antes de commitear cualquier cambio en `lib/` o `test/`.
- Antes de abrir un PR.
- Cuando el usuario pide "valida", "build", "analiza", "testea".
- Cuando un subagente termina una tarea de Flutter y debe confirmar que no rompió nada.

## Comandos canónicos

Todos se ejecutan desde la raíz del repo.

### 1. Instalar dependencias
```bash
flutter pub get
```
Si falla con "SDK version mismatch" → revisar `pubspec.yaml` vs `flutter --version`.

### 2. Análisis estático
```bash
flutter analyze
```
Criterio de éxito: `No issues found!`. Cualquier issue bloquea el commit.

### 3. Tests
```bash
flutter test
```
Criterio: todos los tests pasan. Si hay flaky, reintentar una vez; si persiste, investigar antes de commitear.

### 4. Test individual
```bash
flutter test test/ruta/al/archivo_test.dart
```

### 5. Build web de verificación
```bash
flutter build web --release
```
Criterio: termina sin errores. Output en `build/web/`.

### 6. Run local en Chrome
```bash
flutter run -d chrome
```
Úsalo solo si el usuario pide probar manualmente.

## Flujo "pre-commit" estándar

Antes de cualquier `git commit` de código Flutter, ejecutar en orden:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

Si alguno falla → arreglar y reintentar. Nunca commitear con la suite en rojo.

## Errores conocidos

- **`Target of URI doesn't exist`** → falta crear el archivo o hay un typo en el `import`.
- **`The argument type 'X' can't be assigned to the parameter type 'Y'`** → normalmente un cambio de tipo en Riverpod 3; revisar si cambió `.watch` vs `.read`.
- **`Dart SDK version mismatch`** → el usuario debe actualizar Flutter; detenerse e informar.

## Qué NO hace este skill

- No hace deploy (eso es `despensa-firebase-ops` + `despensa-deploy-web`).
- No toca `pubspec.yaml` sin confirmación explícita.
- No ejecuta `flutter clean` salvo que el usuario lo pida.
```

- [ ] **Step 12.2: Commit**

```bash
git add .claude/skills/despensa-flutter-ops/SKILL.md
git commit -m "feat(fase-0): add despensa-flutter-ops skill"
```

---

## Task 13: Skill `despensa:firebase-ops`

**Files:**
- Create: `.claude/skills/despensa-firebase-ops/SKILL.md`

- [ ] **Step 13.1: Crear skill**

Run: `mkdir -p .claude/skills/despensa-firebase-ops`

Write `.claude/skills/despensa-firebase-ops/SKILL.md`:
```markdown
---
name: despensa-firebase-ops
description: Operaciones Firebase para DespensaInteligente — emuladores, deploy de hosting/functions/firestore rules, logs. Úsalo cada vez que necesites interactuar con Firebase CLI.
---

# despensa-firebase-ops

Skill interno para operar la CLI de Firebase sobre el proyecto `despensa-inteligente-c1f9d`.

## Pre-requisitos

1. `firebase --version` debe funcionar.
2. El usuario ya corrió `firebase login` alguna vez en esta máquina.
3. El proyecto activo es `despensa-inteligente-c1f9d` (verificar con `firebase use`).

Si alguno falla, detenerse y pedir al usuario que lo resuelva.

## Comandos canónicos

### Proyecto activo
```bash
firebase use despensa-inteligente-c1f9d
```

### Emuladores (desarrollo local)
```bash
firebase emulators:start
```
Esto levanta Auth (9099), Firestore (8080), Functions (5001), Hosting (5000). UI en http://localhost:4000.

Para correr solo algunos:
```bash
firebase emulators:start --only auth,firestore,functions
```

### Ejecutar comando contra emulador (para tests de reglas)
```bash
firebase emulators:exec --only firestore "cd functions && npm test"
```

### Deploy — Hosting
```bash
flutter build web --release
firebase deploy --only hosting
```

### Deploy — Functions
```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

### Deploy — Firestore rules
```bash
firebase deploy --only firestore:rules
```

### Deploy — Firestore indexes
```bash
firebase deploy --only firestore:indexes
```

### Deploy completo (web + functions + rules + indexes)
```bash
flutter build web --release && firebase deploy
```

### Logs de Functions
```bash
firebase functions:log --only healthcheck --limit 50
```

### Secrets (OpenAI, Stripe)
```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
```

## Flujo "deploy web" estándar

1. `flutter analyze` verde.
2. `flutter test` verde.
3. `flutter build web --release`.
4. `firebase deploy --only hosting`.
5. Smoke test contra la URL final.

## Qué NO hace este skill

- No modifica `firebase_options.dart` (lo regenera `flutterfire configure`, que solo corre el usuario).
- No expone secretos en logs.
- No corre `firebase init` (reinstala plantillas y puede pisar `firebase.json` — siempre editarlo a mano).
```

- [ ] **Step 13.2: Commit**

```bash
git add .claude/skills/despensa-firebase-ops/SKILL.md
git commit -m "feat(fase-0): add despensa-firebase-ops skill"
```

---

## Task 14: Cierre de Fase 0 — validación global y update del plan maestro

**Files:**
- Modify: `PLAN_IMPLEMENTACION.md` (marcar checkboxes de Fase 0)

- [ ] **Step 14.1: Verificación completa Flutter**

Run:
```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Expected:
- `flutter analyze`: `No issues found!`
- `flutter test`: todos los tests pasan (widget_test, login, dashboard, router → 6 tests en total aprox).
- `flutter build web --release`: termina con `✓ Built build/web` o equivalente.

- [ ] **Step 14.2: Verificación completa Functions**

Run:
```bash
cd functions && npm run build && cd ..
```

Expected: genera `functions/lib/index.js` sin errores.

- [ ] **Step 14.3: Correr `flutter run -d chrome` y verificar a ojo** (opcional si hay humano disponible)

Run: `flutter run -d chrome`

Expected:
- Se abre Chrome.
- Aparece `LoginScreen` con campos de email, contraseña, botones "Entrar", "Crear cuenta", "Entrar como test".
- Al presionar "Entrar como test", redirige a `DashboardScreen` con "Bienvenido 👋" y botón "Cerrar sesión".
- Al presionar "Cerrar sesión", vuelve a `LoginScreen`.

Si no hay humano disponible, skip este step y hacer commit del plan actualizado.

- [ ] **Step 14.4: Marcar Fase 0 como completada en `PLAN_IMPLEMENTACION.md`**

Usar Edit para cambiar cada `- [ ] 0.X` a `- [x] 0.X` dentro del bloque "Fase 0 — Fundaciones & tooling" del archivo.

- [ ] **Step 14.5: Commit final de Fase 0**

```bash
git add PLAN_IMPLEMENTACION.md
git commit -m "docs(fase-0): mark Fase 0 complete in master plan"
```

- [ ] **Step 14.6: Resumen verbal al usuario**

Reportar:
- Número de commits de la fase (debería ser ~11).
- Cantidad de tests pasando.
- Archivos creados (conteo).
- Cualquier TODO diferido a una fase posterior.
- Estado del CI (se valida en el próximo push).

---

## Criterio de salida de la Fase 0

✓ `flutter analyze` verde.
✓ `flutter test` verde (≥ 6 tests entre widget/router).
✓ `flutter build web --release` sin errores.
✓ `functions/lib/index.js` compilado.
✓ `firebase.json` válido y con hosting + functions + firestore configurados.
✓ `firestore.rules` y `firestore.indexes.json` presentes.
✓ Workflow CI creado (la validación real ocurre al pushear).
✓ Dos skills locales (`despensa-flutter-ops`, `despensa-firebase-ops`) en `.claude/skills/`.
✓ `PLAN_IMPLEMENTACION.md` con Fase 0 marcada como completada.
✓ Repo en estado que permite avanzar a Fase 1 sin deuda técnica.

---

## Notas para el ejecutor

1. **TDD disciplinado:** en Tasks 3, 4, 5 escribir el test primero y verificar que falla antes de implementar. No saltarse este paso aunque parezca obvio.
2. **Commits atómicos:** un commit por task (o por sub-bloque cuando el task lo indica). No mezclar.
3. **Model switching:** este plan está optimizado para ejecutarse con Sonnet 4.6. Las tareas son mecánicas; no se requiere razonamiento pesado. Si una tarea pide una decisión arquitectónica nueva (no debería), escalar a Opus.
4. **Bloqueos conocidos:** si `npm install` en `functions/` falla por red, reintentar una vez; si persiste, detenerse. Si `flutter pub get` falla por SDK version, el usuario debe actualizar Flutter antes de seguir.
5. **No tocar** `lib/firebase_options.dart`, `lib/services/auth.service.dart`, ni nada en `android/`, `ios/`, `macos/`, `windows/`, `linux/` durante esta fase.
