# CLAUDE.md

Guía para Claude Code al trabajar en este repositorio.

## Project Overview

DespensaInteligente es una app mobile Flutter (Android/iOS/Web) para gestión de despensa doméstica con IA. Los usuarios escanean productos, controlan vencimientos, y reciben recetas generadas por Gemini según lo que tengan disponible. Incluye hogares compartidos con múltiples miembros.

**Firebase Project ID:** `despensa-inteligente-c1f9d`
**Estado actual:** Fase 4 (recetas IA) y Fase 5 (billing Flow + Stripe) mergeadas. Fase 6 (UX web + comunidad) planificada — ver `docs/plans/FASE_6_UX_COMUNIDAD.md`.

⚠️ **Importante**: Las Cloud Functions de Fase 4 y 5 (`generarReceta`, `crearSuscripcionFlow`, `flowWebhook`, etc.) **aún no están deployadas a producción**. Sólo las antiguas (`lookupProductoGlobal`, `proponerProductoGlobal`). Por eso generar receta en la web real hoy falla — es el primer ítem de Fase 6.

## Common Commands

```bash
# Dependencias
flutter pub get
(cd functions && npm install)

# Correr mobile (device conectado o emulador)
flutter run

# Correr web
flutter run -d chrome --web-port 5000

# Análisis y tests Flutter
flutter analyze
flutter test

# Tests backend (vitest)
(cd functions && npm test)

# Builds release
flutter build apk --release      # APK fat, para testing
flutter build appbundle --release # AAB para Play Store
flutter build ios --release       # requiere cuenta Apple Developer

# Deploy selectivo
firebase deploy --only firestore:rules --project despensa-inteligente-c1f9d
firebase deploy --only hosting --project despensa-inteligente-c1f9d
firebase deploy --only functions:generarReceta --project despensa-inteligente-c1f9d

# Regenerar config Firebase (si cambiás package names o agregás apps)
flutterfire configure
```

## Architecture

### State management & DI
**Riverpod** (`flutter_riverpod`) para estado y DI. Providers se definen junto al servicio que proveen (ej. `usuarioRepositoryProvider` en `lib/features/auth/data/usuario_repository.dart`).

### Project Structure
```
lib/
├── main.dart              # Entry point, init Firebase, tema oscuro #CDE600
├── app/
│   ├── router.dart        # go_router con redirects de auth y onboarding
│   └── theme.dart         # DespensaTheme.dark()
├── features/
│   ├── auth/              # login, register, usuario model y repo
│   ├── hogares/           # crear hogar, invitaciones, miembros
│   ├── despensa/          # CRUD ítems, escáner barcode, vencimientos
│   ├── productos_globales/# base comunitaria de productos (lookup + propose)
│   ├── scanner/           # BarcodeInput (cámara + teclado)
│   ├── recetas/           # generación IA + detalle + historial
│   ├── plan/              # PlanConfig, StripeRepository, FlowRepository
│   └── home/              # DashboardScreen
└── services/              # auth service, firestore provider

functions/src/
├── recetas/generarReceta.ts     # Callable Gemini (no deployada aún)
├── productos/                    # lookupProductoGlobal, proponerProductoGlobal (deployadas)
├── stripe/                       # checkout + webhook (código listo, no deployado)
└── flow/                         # crearSuscripcionFlow + return + webhook (código listo, no deployado)

site/                      # Landing + legal (privacidad.html, terminos.html)
                           # Deployado en https://despensa-inteligente-c1f9d.web.app

docs/
├── HANDOFF.md             # Handoff general del proyecto
├── plans/                 # Planes internos (gitignored)
│   ├── FASE_1-5 ...
│   └── FASE_6_UX_COMUNIDAD.md    # Plan actual activo
└── store/                 # Textos de listing Play Store + App Store
```

### Auth flow
`buildRouter()` en `lib/app/router.dart` con `go_router`. Redirects declarativos:
- No logueado → `/login`
- Logueado sin hogar → `/onboarding/hogar`
- Logueado con hogar → `/` (Dashboard)

El estado se lee de `firebaseAuthStateProvider` (stream de `authStateChanges`) y `usuarioStreamProvider` (doc de Firestore).

### Firebase stack
- **Auth**: email/password + Google Sign-In
- **Firestore**: `/usuarios`, `/hogares/{id}/{despensa, recetas, invitaciones}`, `/productos_globales`, `/productos_globales_drafts`, `/planes_config`
- **Rules** en `firestore.rules` — ya desplegadas con hardening (plan field protegido del cliente, invitaciones restringidas)
- **Functions v2** en `functions/src/`, runtime Node 20
- **Hosting** sirve `site/` (no `build/web`)

### Package identities
- Android applicationId: `com.webiados.despensa_inteligente`
- iOS bundle ID: `com.webiados.despensaInteligente`
- Keystore de release: `android/app/upload-keystore.jks` (gitignored, backup en iCloud del dueño)

### Pasarela de pagos
- **Flow.cl** (Chile): pasarela activa del MVP. Código listo, esperando registro del dueño.
- **Stripe**: código presente para expansión futura internacional, sin conectar a la UI activa.
- **iOS**: decisión tomada (ver `docs/store/README.md`) — implementar IAP nativo cuando toque App Store.

### Env vars (`.env`)
Solo para dev local — `flutter_dotenv` está instalado pero el código ya no lo usa activamente (migrado a Gemini via Cloud Functions). Las claves viven como Firebase secrets:
- `GEMINI_API_KEY` — para `generarReceta`
- `FLOW_API_KEY`, `FLOW_SECRET_KEY`, `FLOW_BASE_URL`, `FLOW_PLAN_ID`, `FLOW_URL_RETURN_BASE`, `FLOW_SUCCESS_URL`, `FLOW_ERROR_URL` — para suscripciones Flow
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` — sólo si se activara Stripe
- `OPENFOODFACTS` — sin key, API pública

**Nunca** commitear `.env`, `android/key.properties`, `android/app/upload-keystore.jks`.

## Git Workflow

- `main` es producción
- Cada feature/fix/chore en branch `feature/*`, `fix/*`, `chore/*`, `docs/*`
- PRs a main, CI verde antes de mergear, squash o merge commit según preserve la historia TDD
- Commits siguen patrón TDD: red → green → commit (una unidad pequeña por commit cuando aplique)
- Co-autor Claude Opus en los commits que asistió

## Testing discipline (TDD)

- Backend (`functions/`): 84 tests vitest. Cada Cloud Function tiene su `*.test.ts` con fakes de Firestore + dependencies. Patrón: `buildXHandler({deps})` + runtime wrapper `onCall`/`onRequest`.
- Flutter: 96 tests widget + unit. Usan `fake_cloud_firestore` (no valida rules).
- CI corre ambos en cada PR (`.github/workflows/ci.yml`).

## Key Dependencies

### Dart/Flutter
- `flutter_riverpod` — state management primario
- `go_router` — navegación con redirect
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`
- `mobile_scanner ^7.2.0` — barcode scanner (se actualizó desde v5 por conflicto nanopb con Firebase)
- `url_launcher` — abrir Flow/Stripe externamente
- `image_picker` — futura captura de fotos para productos_globales
- `flutter_dotenv` — aún declarado, sin uso activo post-migración a Gemini

### Node (functions)
- `firebase-admin`, `firebase-functions` v2
- `@google/generative-ai` para Gemini
- `stripe` para checkout/webhooks
- `vitest` para tests

## SDK Constraints
Dart SDK `^3.9.2` (Flutter 3.22+, actualmente corriendo 3.35.x).
Android: `minSdk` por Flutter default (~21), `targetSdk` y `compileSdk` también por default.
iOS: deployment target 15.0 (bumpeado desde 13 por cloud_firestore).
