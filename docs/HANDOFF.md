# DespensaInteligente — Handoff Document

**Última actualización:** 2026-04-14
**Rama actual:** `feature/fase-1-auth-hogar`
**Último commit:** `b679dff` (docs(fase-1): mark Fase 1 complete in master plan)
**Estado:** Fase 0 + Fase 1 completas. PR pendiente de crear.

---

## 1. Cómo retomar el trabajo en otro terminal

```bash
# 1. Clonar e ir a la rama
git clone https://github.com/Pipedsl/despensa_inteligente.git
cd despensa_inteligente
git checkout feature/fase-1-auth-hogar

# 2. Dependencias
flutter pub get

# 3. Verificar que todo está verde
flutter analyze          # debe pasar limpio
flutter test             # 31 tests, todos deben pasar
flutter build web --release   # build debe compilar

# 4. Variables de entorno
# Crear .env en la raíz (NO commitear) con:
#   OPENAI_API_KEY=sk-...
#   TEST_USER_EMAIL=...
#   TEST_USER_PASSWORD=...
```

Para correr la app en Chrome: `flutter run -d chrome`.

---

## 2. Stack y proveedores

| Capa | Tecnología | Estado |
|---|---|---|
| Frontend | Flutter Web (Dart `^3.9.2`) | Activo |
| State management | `flutter_riverpod` 3 | Activo |
| Routing | `go_router` 16 | Activo |
| Auth | Firebase Auth (email/pass + Google popup) | Activo |
| DB | Cloud Firestore (multitenant) | Activo |
| Backend custom | Firebase Cloud Functions v2 (Node 20 + TS) | Planeado Fase 3+ |
| IA | OpenAI (recetas + normalizador barcode) | Planeado Fase 3/4 |
| Billing | Stripe (Checkout + webhook) | Planeado Fase 5 |
| Hosting | Firebase Hosting (web) | Planeado Fase 6 |
| Testing | `flutter_test` + `fake_cloud_firestore` 4.1.0 | Activo |

**Firebase Project ID:** `despensa-inteligente-c1f9d`
**Repositorio:** https://github.com/Pipedsl/despensa_inteligente

---

## 3. MCPs configurados

### `.mcp.json` en la raíz del proyecto

```json
{
  "mcpServers": {
    "firebase": {
      "command": "npx",
      "args": ["-y", "firebase-tools@latest", "experimental:mcp"],
      "env": { "FIREBASE_PROJECT_ID": "despensa-inteligente-c1f9d" }
    }
  }
}
```

- **Firebase MCP** — expuesto vía `firebase-tools experimental:mcp`. Permite a Claude Code leer/modificar Firestore rules, listar colecciones, desplegar Functions, etc. Requiere `firebase login` previo en el terminal.
- **Context7 MCP** — ya instalado como plugin de Claude Code (no requiere config local). Usar para docs actualizadas de librerías.
- **GitHub MCP** — disponible como plugin pero necesita `gh auth login` antes de usarse para crear PRs/issues.

### Pendientes de instalar cuando correspondan

- **Stripe MCP** (Fase 5): agregar a `.mcp.json` el server `@stripe/mcp --tools=all` con `STRIPE_SECRET_KEY` desde `.env`.

---

## 4. Estado por fase del plan maestro

Ver `PLAN_IMPLEMENTACION.md` y `docs/plans/FASE_*.md` para el detalle completo.

| Fase | Título | Estado | Modelo recomendado |
|---|---|---|---|
| 0 | Bootstrap proyecto | Completa | Sonnet |
| 1 | Auth real + Hogar multitenant | **Completa** | Sonnet |
| 2 | Despensa CRUD core (sin barcode) | Pendiente | Sonnet |
| 3 | Productos globales + barcode + normalizador IA | Pendiente | **Opus** (diseño prompts) |
| 4 | Recetas IA + rate limiting por plan | Pendiente | Opus (prompts) / Sonnet (código) |
| 5 | Stripe billing (Checkout + webhook) | Pendiente | Sonnet |
| 6 | Deploy web + observabilidad | Pendiente | Sonnet |
| 7 | Android/iOS store prep | Pendiente | Sonnet |

---

## 5. Lo que está construido en Fase 1

### Estructura `lib/`

```
lib/
├── main.dart                      # Bootstrap + MaterialApp.router con buildRouter()
├── app/
│   ├── router.dart                # buildRouter + calculateRedirect (función pura)
│   └── theme.dart                 # Dark + accent #cde600
├── services/
│   ├── auth.service.dart          # AuthService + Google signInWithPopup
│   └── firebase/
│       └── firestore_provider.dart
├── features/
│   ├── auth/
│   │   ├── domain/usuario.dart
│   │   ├── data/
│   │   │   ├── usuario_repository.dart
│   │   │   └── usuario_providers.dart   # usuarioStreamProvider
│   │   └── presentation/
│   │       ├── login_screen.dart         # email/pass + Google
│   │       └── register_screen.dart      # nombre + email + pass
│   ├── hogares/
│   │   ├── domain/hogar.dart             # Hogar + Invitacion
│   │   ├── data/hogar_repository.dart    # crear, listar, invitaciones, join por código
│   │   └── presentation/
│   │       ├── onboarding_hogar_screen.dart
│   │       └── mis_hogares_screen.dart
│   └── home/
│       └── presentation/dashboard_screen.dart
```

### Decisiones arquitectónicas clave

1. **Riverpod lazy pattern**: nunca `ref.read(authServiceProvider)` en `build()`; sólo en callbacks. Evita inicializar Firebase en widget tests.
2. **`calculateRedirect` como función pura**: permite testear routing sin go_router real ni Firebase. Se le inyectan `bool isLoggedIn` y `bool? hasHogar` (donde `null` = cargando, no redirigir).
3. **`fake_cloud_firestore` 4.1.0**: versión compatible con `cloud_firestore ^6.0.2`. Repositorios reciben `FirebaseFirestore` por constructor para poder inyectar el fake en tests.
4. **Multitenant Firestore**: cada hogar tiene `miembros: Map<uid, 'owner'|'member'>` + `miembrosIds: List<uid>` redundante para poder usar `arrayContains` en queries. Reglas usan helpers `isAuth()`, `isMember(hogarId)`, `isOwner(hogarId)`.
5. **Invitaciones por código**: 6 chars `A-Z0-9` con `Random.secure()`, expiran en 24h, se guardan en subcolección `/hogares/{id}/invitaciones/{codigo}`. Para unirse se usa `collectionGroup('invitaciones').where('codigo', ...)` y luego una transacción que actualiza `miembros` + `miembrosIds` y marca la invitación como usada.
6. **Rutas**:
   - `/` Dashboard (protegida, requiere hogar activo)
   - `/login` pública
   - `/registro` pública
   - `/onboarding/hogar` protegida, solo si no tiene hogar
   - `/hogares` protegida, gestión de hogares

### Tests (31 total, todos pasando)

- `test/app/router_test.dart` — 10 tests de `calculateRedirect` (incluye caso `hasHogar == null`)
- `test/features/auth/` — usuario model (2), usuario_repository con fake firestore (5), login_screen (3), register_screen (1)
- `test/features/hogares/` — hogar model (4), hogar_repository (5), onboarding (1)
- `test/features/home/dashboard_screen_test.dart` — con `ProviderScope`

### Reglas Firestore vigentes (`firestore.rules`)

Ya desplegadas conceptualmente (ver archivo). Deploy real pendiente con `firebase deploy --only firestore:rules` — hacer antes de abrir Fase 2 a usuarios reales.

---

## 6. Tareas pendientes inmediatas

1. **Crear PR de Fase 1**
   ```bash
   gh auth login                 # una sola vez
   gh pr create --base main \
     --title "feat(fase-1): auth real + hogar multitenant" \
     --body-file docs/plans/FASE_1_AUTH_HOGAR.md
   ```
   URL directa: https://github.com/Pipedsl/despensa_inteligente/pull/new/feature/fase-1-auth-hogar

2. **Deploy inicial de Firestore rules** a staging para probar signup real:
   ```bash
   firebase login
   firebase use despensa-inteligente-c1f9d
   firebase deploy --only firestore:rules
   ```

3. **Iniciar Fase 2 — Despensa CRUD core**
   - Nueva rama desde `main` (tras mergear Fase 1): `feature/fase-2-despensa-crud`
   - Plan detallado en `docs/plans/FASE_2_DESPENSA.md` (crear si no existe a partir del plan maestro)
   - Modelo: **Sonnet 4.6** es suficiente

---

## 7. Convenciones de trabajo con Claude Code en este repo

- **TDD estricto por tarea**: test rojo → implementación mínima → test verde → commit.
- **Commits pequeños** por sub-tarea (ej: `feat(fase-1): add UsuarioRepository with fake firestore tests`).
- **Nunca** commitear `.env`, `lib/firebase_options.dart` está autogenerado por `flutterfire configure`.
- **`flutter analyze` debe estar limpio** antes de cada commit.
- **Widget tests**: siempre envolver en `ProviderScope`. No tocar `firebaseAuthProvider` directo; usar los helpers de `authServiceProvider`.
- **Plan maestro**: actualizar `PLAN_IMPLEMENTACION.md` marcando `[x]` cada sub-sección cuando termine.
- **Documentos de fase**: vive en `docs/plans/FASE_N_*.md`, siguen estructura tarea-por-tarea con tests incluidos.

---

## 8. Contacto con contexto previo

Si necesitás el transcript completo de la sesión que construyó Fase 1:
`/Users/felipenavarretenavarrete/.claude/projects/-Users-felipenavarretenavarrete-Desktop-proyectosWebiados-despensa-inteligente/baa6a026-4978-4f99-9b5a-5801088ad30f.jsonl`

CLAUDE.md en la raíz tiene las instrucciones vivas del proyecto que Claude Code carga automáticamente en cada sesión.
