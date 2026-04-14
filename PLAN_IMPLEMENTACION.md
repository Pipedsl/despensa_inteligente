# Plan de Implementación — DespensaInteligente (Web + Base móvil)

> **Fecha:** 2026-04-13
> **Objetivo:** Llevar DespensaInteligente desde el scaffold actual hasta una web funcional con despensa multitenant, base global de productos enriquecida por IA, recetas con IA restringidas por plan, billing y deploy, y dejar sentadas las bases para publicación posterior en Play Store y App Store.
> **Target inmediato:** Web (Firebase Hosting).
> **Target diferido:** Android + iOS (Fase 7).

---

## 0. Estado actual del repositorio

Hallazgos después de revisar `lib/` y `CLAUDE.md`:

- `lib/main.dart` referencia `DashboardScreen` **que no existe en el código**. El build actual probablemente rompe.
- `lib/features/auth/presentation/login_screen.dart` contiene únicamente `// TODO Implement this library.`
- `lib/services/firestore_service.dart` y `lib/services/recipe_service.dart` están efectivamente vacíos.
- `lib/services/auth.service.dart` es lo único implementado: expone `firebaseAuthProvider`, `firebaseAuthStateProvider`, `AuthService` (signIn/signUp/signInAsTestUser/signOut) y `authServiceProvider`.
- `lib/firebase_options.dart` ya tiene configuración para `web`, `android`, `ios` (proyecto `despensa-inteligente-c1f9d`).
- `web/` tiene `index.html`, `manifest.json`, favicon e iconos — scaffold web listo.
- `pubspec.yaml` declara `go_router`, `flutter_riverpod`, `image_picker`, `flutter_dotenv`, Firebase stack; `go_router` aún no está cableado.
- `.env` existe con `OPENAI_API_KEY` y credenciales de test (no commiteado).
- Solo dos commits en git: scaffold inicial + CLAUDE.md.

**Conclusión:** La app **no** está funcional actualmente en ningún target. Hay que reconstruir desde un scaffold medio-completo. La ventaja: Firebase, Riverpod y web ya están configurados.

---

## 1. Arquitectura objetivo

### 1.1 Stack

| Capa | Elección | Justificación |
|---|---|---|
| Cliente | Flutter Web (Flutter 3.22+, Dart 3.9) | Ya hay scaffold y permite reutilizar todo para Android/iOS |
| State / DI | `flutter_riverpod` 3 | Ya instalado, es el estándar del proyecto |
| Routing | `go_router` 16 | Ya instalado, imprescindible para web (deep links, URLs) |
| Auth | Firebase Auth (Email + Google Sign-In para web) | Ya configurado |
| DB cliente | Cloud Firestore | Ya configurado, multitenant via reglas |
| Backend lógico | Cloud Functions 2ª gen (Node/TS) | Necesario para: agente IA, webhooks Stripe, rate limit, writes privilegiados a `productos_globales` |
| IA | OpenAI (GPT-4o-mini para normalización, GPT-4o para recetas) vía Functions | Se evita exponer API key al cliente, habilita caching y rate limiting |
| Barcode | `mobile_scanner` (soporta web vía MediaDevices) + entrada manual | Paquete mantenido con soporte web |
| Hidratación externa | OpenFoodFacts API (fallback cuando barcode no existe en DB global) | Gratis, público, gran cobertura |
| Billing | Stripe Checkout + Stripe Customer Portal + webhooks a Functions | Estándar, integración simple |
| Hosting | Firebase Hosting (web) | Ya en el ecosistema Firebase |
| CI/CD | GitHub Actions → Firebase Hosting (preview + production) | Nativo y gratis para el scope actual |

### 1.2 Modelo de datos Firestore (borrador)

```
/usuarios/{uid}
  email, displayName, photoUrl, createdAt
  hogarActivo: hogarId
  plan: "free" | "pro"
  stripeCustomerId
  aiUsage: { month: "2026-04", tokensUsados: N, requestsUsados: N }

/hogares/{hogarId}
  nombre, creadoPor: uid, createdAt
  miembros: { uid: "owner" | "member" }   // map para consultas rápidas
  miembrosIds: [uid1, uid2]               // array para where-in

/hogares/{hogarId}/despensa/{itemId}
  productoGlobalId: ref → /productos_globales/{barcode}
  nombre, cantidad, unidad
  fechaVencimiento: timestamp
  fechaCompra, precio, moneda: "CLP"
  tienda
  agregadoPor: uid
  notas
  createdAt, updatedAt

/productos_globales/{barcode}
  barcode, nombre, marca
  categorias: []
  imagenUrl
  nutricional: { energiaKcal, proteinasG, grasasG, carbosG, sodioMg, ... }
  contribuidores: [uid]         // quién ha aportado datos
  camposFaltantes: []           // lista de claves que aún no están llenas
  ultimaActualizacion
  source: "user" | "openfoodfacts" | "ia"
  estado: "pendiente_revision" | "publicado"

/productos_globales_drafts/{draftId}    // staging antes del agente IA
  input crudo del usuario, barcode, uid, createdAt

/hogares/{hogarId}/invitaciones/{codigo}
  codigo (6 caracteres), creadoPor, expiraEn, usadoPor

/hogares/{hogarId}/recetas/{recetaId}
  generadaPor: uid, fecha
  ingredientesUsados: [{ itemId, nombre }]
  contenido: { titulo, pasos, tiempo, porciones }
  modeloIa: "gpt-4o-mini" | "gpt-4o"
  tokensUsados

/planes_config/{planId}          // mantenido por admin, no escribible por usuarios
  id: "free" | "pro"
  maxRecetasMes, maxTokensMes, maxMiembrosHogar, maxHogares
  stripePriceId
```

Reglas de seguridad clave:
- `despensa/*`: solo accesibles si `uid ∈ hogares/{hogarId}/miembrosIds`.
- `productos_globales/*`: lectura pública autenticada; escritura **solo desde Cloud Functions** (el agente IA).
- `usuarios/{uid}`: solo el propio uid.
- `planes_config/*`: lectura autenticada, escritura solo admin.

### 1.3 Estructura de carpetas objetivo

```
lib/
  main.dart
  app/
    router.dart                 # go_router config + guards auth
    theme.dart                  # tema dark + accent #cde600
  core/
    errors/
    result.dart
    extensions/
  features/
    auth/
      data/       domain/       presentation/
    hogares/
      data/       domain/       presentation/
    despensa/
      data/       domain/       presentation/
    productos_globales/
      data/       domain/       presentation/   # solo lectura desde cliente
    recetas/
      data/       domain/       presentation/
    plan/
      data/       domain/       presentation/   # límites, billing, upgrade
    scanner/
      data/       presentation/
  services/
    firebase/
    openai/                     # solo tipos — llamadas reales desde Functions
  shared/
    widgets/
functions/                      # Cloud Functions (TS) — nuevo directorio
  src/
    ai/
      normalizador.ts
      generadorRecetas.ts
    ratelimit/
    stripe/
    productosGlobales/
    index.ts
```

---

## 2. Fases de implementación

Cada fase termina en un estado **demo-able** (se puede lanzar `flutter run -d chrome` y mostrar algo que funciona).

### Fase 0 — Fundaciones & tooling  *(1–2 días)*

**Objetivo:** Dejar el repo compilable y con la infraestructura de trabajo lista.

- [x] 0.1 Crear `DashboardScreen` placeholder (pantalla vacía con el tema aplicado y botón signOut) para que `main.dart` compile.
- [x] 0.2 Implementar `LoginScreen` mínimo (email + password + botón "entrar como test").
- [x] 0.3 Crear `lib/app/router.dart` con `go_router` y rutas: `/login`, `/`. Guard `calculateRedirect` puro con 6 tests.
- [x] 0.4 Mover el tema a `lib/app/theme.dart`.
- [x] 0.5 Crear estructura de carpetas `features/*` vacías (ver sección 1.3).
- [x] 0.6 `firebase.json` expandido manualmente con Hosting + Functions + Firestore + emulators (evita `firebase init` interactivo).
- [x] 0.7 Inicializar `functions/` como proyecto TS con ESLint.
- [x] 0.8 Crear `firestore.rules` (deny-all) y `firestore.indexes.json` iniciales.
- [x] 0.9 Agregar GitHub Actions: workflow que en PR corre `flutter analyze`, `flutter test`, `flutter build web` + functions build.
- [x] 0.10 Crear skills locales `despensa-flutter-ops` y `despensa-firebase-ops` en `.claude/skills/`.
- [x] 0.11 11 commits atómicos. `flutter analyze` verde, 9 tests pasando, `flutter build web --release` ✓.

**Criterio de salida:** `flutter run -d chrome` abre `LoginScreen`, login de test funciona, redirige a `DashboardScreen` vacío, `flutter analyze` pasa, CI verde.

---

### Fase 1 — Auth real + Hogar multitenant  *(3–4 días)*

**Objetivo:** Un usuario puede registrarse, crear un hogar, invitar a otro miembro y ambos ver el mismo hogar.

- [x] 1.1 Habilitar Google Sign-In en Firebase Auth + configurar en `web/index.html` y botón en `LoginScreen`.
- [x] 1.2 Pantalla de registro (email + contraseña + nombre).
- [x] 1.3 Al crear usuario: crear documento `/usuarios/{uid}` con plan "free".
- [x] 1.4 Feature `hogares`:
  - [x] 1.4.1 Modelo `Hogar` y `HogarMember`.
  - [x] 1.4.2 `HogarRepository` con métodos `crear`, `listarPorUsuario`, `invitarPorCodigo`, `unirsePorCodigo`, `cambiarRol`.
  - [x] 1.4.3 Pantalla "Mis hogares" con lista, crear nuevo, generar código de invitación (6 chars, expira en 24h).
  - [x] 1.4.4 Pantalla "Unirse a hogar por código".
  - [x] 1.4.5 Selector de hogar activo persistido en `usuarios/{uid}.hogarActivo`.
- [x] 1.5 Escribir `firestore.rules` para multitenant:
  - `hogares/{id}` escribible solo por `owner`; legible por `miembros`.
  - `hogares/{id}/despensa/**` legible/escribible por miembros.
- [x] 1.6 Tests: repositorios con `fake_cloud_firestore` (Usuario + Hogar + invitaciones).
- [x] 1.7 Guard en `router.dart` que fuerza al usuario sin hogar a pasar por `/onboarding/hogar`.

**Criterio de salida:** Dos usuarios distintos (creados en el emulador) comparten el mismo hogar vía código de invitación, ven el mismo dashboard.

---

### Fase 2 — Despensa (CRUD core sin barcode)  *(3–4 días)*

**Objetivo:** El hogar puede gestionar productos con vencimiento, precio, cantidad, tienda. Ordenamiento por proximidad a vencer.

- [x] 2.1 Modelo `ItemDespensa` (sección 1.2).
- [x] 2.2 `DespensaRepository` sobre `/hogares/{hogarId}/despensa/*`.
- [x] 2.3 Pantalla `DespensaScreen`:
  - Lista ordenada por `fechaVencimiento` ascendente.
  - Badges: rojo (<3 días), amarillo (<7 días), verde (resto).
  - Pull-to-refresh, contador de ítems **con indicador `X / maxProductos`**.
  - Filtro por texto.
- [x] 2.4 Pantalla `AgregarItemScreen` (formulario manual por ahora): nombre, cantidad, unidad, fecha vencimiento (date picker), **precio (opcional)**, **tienda (opcional)**, **cantidad comprada (opcional)**.
- [x] 2.5 Pantalla `DetalleItemScreen` con editar / eliminar.
- [x] 2.6 Notificación visual: banner si hay ítems venciendo en 48h.
- [x] 2.7 **Enforcement de `maxProductos` por plan**: contador atómico en `/hogares/{hogarId}` (`productosActivos`) mantenido con `FieldValue.increment` en create/delete. Si `productosActivos >= plan.maxProductos` → bloqueo con CTA al upgrade. Se decrementa también cuando un ítem se marca como consumido o vencido.
- [x] 2.8 Tests: widget test de ordenamiento, unit test de repo con `fake_cloud_firestore`, test del contador atómico bajo carrera.

**Criterio de salida:** Un usuario puede agregar 10 productos manualmente, verlos ordenados por vencimiento, editarlos y eliminarlos. Ambos miembros del hogar los ven en tiempo real.

---

### Fase 3 — Productos globales + barcode + agente IA normalizador  *(6–8 días)*

**Objetivo:** Al escanear un código de barras la app rellena el producto automáticamente; nuevos aportes enriquecen una base global; un agente IA valida/corrige antes de persistir.

- [ ] 3.1 Integrar `mobile_scanner` y verificar funcionamiento en Chrome (requiere HTTPS o localhost).
- [ ] 3.2 Componente `BarcodeInput` con dos modos: cámara y teclado.
- [ ] 3.3 Cloud Function `lookupProductoGlobal(barcode)`:
  - 3.3.1 Busca en `/productos_globales/{barcode}`. Si existe → retorna.
  - 3.3.2 Si no existe → consulta OpenFoodFacts. Si encuentra → crea draft con `source: "openfoodfacts"` y dispara pipeline de normalización.
  - 3.3.3 Si tampoco existe → retorna `null` para que el usuario llene manualmente.
- [ ] 3.4 Cloud Function `proponerProductoGlobal(draft)` (trigger cuando usuario agrega un ítem con barcode nuevo o datos incompletos):
  - 3.4.1 Guarda draft en `/productos_globales_drafts/{id}`.
  - 3.4.2 Invoca **agente IA normalizador** (GPT-4o-mini) con prompt:
    > Eres un normalizador de productos de supermercado chilenos. Recibirás un input con barcode, nombre, marca, categoría y opcionales nutricionales. Debes: corregir typos, capitalización, expandir abreviaciones ("lt"→"1 L"), validar que la categoría exista en la taxonomía `[...]`, y devolver JSON con `{nombre, marca, categoria, confianza: 0-1, correcciones: [...]}`.
  - 3.4.3 Si `confianza >= 0.8`: merge con `/productos_globales/{barcode}`, respetando campos ya llenos (solo rellena `camposFaltantes`). Agrega `uid` a `contribuidores`.
  - 3.4.4 Si `< 0.8`: deja en `pendiente_revision`; devuelve al cliente los datos sugeridos para que el usuario confirme antes de guardar.
- [ ] 3.5 **Lógica de completado progresivo:** cuando un segundo usuario agrega el mismo barcode con datos nutricionales, el normalizador hace merge rellenando solo `camposFaltantes`. Nunca sobrescribe datos existentes excepto con mayoría (3+ aportes coincidentes).
- [ ] 3.6 Actualizar `AgregarItemScreen` para: escanear → autocompletar formulario → usuario confirma → guarda en despensa y dispara `proponerProductoGlobal`.
- [ ] 3.7 Índice Firestore: por `barcode` y por `camposFaltantes` para dashboards internos.
- [ ] 3.8 Tests: Function con emulador + fixture de OpenFoodFacts, caso de merge progresivo.

**Criterio de salida:** Un usuario escanea un producto nunca visto, el agente IA lo normaliza, queda en la DB global. Un segundo usuario escanea el mismo y la info se autocompleta.

---

### Fase 4 — Recetas con IA + planes & rate limiting  *(4–5 días)*

**Objetivo:** Generar recetas priorizando productos próximos a vencer, con rate limit por plan y optimización de costos.

#### 4.0 Economía de tokens y modelo de precios

**Precios OpenAI de referencia** (USD por 1M de tokens, revisar trimestralmente — pueden cambiar):

| Modelo | Input | Input cacheado | Output |
|---|---|---|---|
| `gpt-4o-mini` | $0.15 | $0.075 | $0.60 |
| `gpt-4o` | $2.50 | $1.25 | $10.00 |

**Costo estimado por operación** (prompt system ~600 tokens cacheables, prompt variable ~400 tokens, output ~800 tokens):

| Operación | Modelo | Costo USD |
|---|---|---|
| Generar receta | gpt-4o-mini | ~$0.0006 |
| Generar receta | gpt-4o | ~$0.0098 |
| Normalizar producto (200 in + 150 out) | gpt-4o-mini | ~$0.00012 |

**Optimizaciones aplicadas** (sección 4.3 + Functions):
- Prompt caching de OpenAI (system prompt estable).
- Cache interno por hash de `(ingredientes priorizados, preferencias)` — hit no consume cuota.
- Modelo `gpt-4o-mini` para normalizador siempre.
- Modelo según plan para recetas (mini en Free, 4o en Pro).

**Modelo de precios (Chile — CLP):** un solo plan pagado es suficiente para el MVP. Razones: simplifica la decisión del usuario, reduce estado en Stripe/Firestore/UI, y permite validar el price point antes de partir tiers. Si el producto gana tracción se parte después en "Plus/Pro".

| Límite | Free | Pro ($3.990 CLP / mes ≈ $4.20 USD) |
|---|---|---|
| Recetas/mes | 3 | 50 |
| Modelo IA recetas | gpt-4o-mini | gpt-4o |
| Hogares | 1 | 3 |
| Miembros por hogar | 4 | ilimitados |
| **Productos activos en despensa** | **30** | **300** |
| Historial de recetas | últimas 10 | completo |
| Scanner + DB global | ✓ | ✓ |

**Unit economics del plan Pro (peor caso, usuario agota 50 recetas):**

| Concepto | USD |
|---|---|
| Ingreso bruto | $4.20 |
| OpenAI (50 × $0.0098) | −$0.49 |
| Firebase (Firestore/Functions/Hosting marginal) | −$0.10 |
| Stripe fees (2.9% + $0.30) | −$0.42 |
| **Margen bruto por usuario/mes** | **~$3.19 (76%)** |

Con cache de recetas por hash (hit rate estimado 20–40%) el costo OpenAI efectivo baja proporcionalmente. Con 200 suscriptores Pro activos en 6 meses: ingreso ~$840/mes, margen bruto ~$638/mes — suficiente para cubrir Firebase Blaze y dominio propio con holgura.

**Revisión del modelo:** tras 500 usuarios totales o 50 suscriptores Pro, recalcular costos reales (dashboard con `costUsd` por evento en Functions) y re-evaluar precio y límites.

- [ ] 4.1 Crear documentos `planes_config/free` y `planes_config/pro` con los valores de la tabla anterior (`maxRecetasMes`, `maxProductos`, `maxHogares`, `maxMiembrosHogar`, `modeloReceta`, `stripePriceId`, `historialLimite`).
- [ ] 4.2 Cloud Function `generarReceta(hogarId, preferencias)`:
  - 4.2.1 Lee usuario y verifica `plan` + `aiUsage.month`. Si pasó el límite → error `PLAN_LIMIT_EXCEEDED`.
  - 4.2.2 Lee despensa del hogar, ordena por proximidad a vencer, toma top 10.
  - 4.2.3 Construye prompt estable (cacheable) + sección variable con ingredientes. Usa **prompt caching** de OpenAI.
  - 4.2.4 Llama a GPT-4o con `response_format: json_object`.
  - 4.2.5 Guarda en `/hogares/{id}/recetas/{id}` + incrementa `aiUsage` atómicamente.
- [ ] 4.3 Cache de recetas similares: hash de `(set de ingredientes priorizados, preferencias)` → si existe receta <7 días con el mismo hash, devolver esa y **no consumir** la cuota. Guardar bandera `from_cache: true`.
- [ ] 4.4 Pantalla `RecetasScreen`: botón "Generar receta", lista de recetas previas, indicador de cuota restante del mes.
- [ ] 4.5 Pantalla `DetalleRecetaScreen`: pasos, porciones, ingredientes resaltando los que están próximos a vencer.
- [ ] 4.6 Pantalla `UpgradeScreen` (vacía por ahora, se llena en Fase 5) que se muestra cuando se excede la cuota.
- [ ] 4.7 Tests: unit test del selector de ingredientes (prioriza vencimiento), emulator test del rate limit.

**Criterio de salida:** Usuario free genera 5 recetas, a la 6ª ve el paywall. Usuarios marcados manualmente como `pro` generan sin bloqueo.

---

### Fase 5 — Billing con Stripe  *(4–5 días)*

**Objetivo:** El usuario puede upgradearse a Pro, pagar, y el plan se refleja inmediatamente.

- [ ] 5.1 Crear productos + precios en Stripe dashboard (modo test). Guardar `stripePriceId` en `planes_config/pro`.
- [ ] 5.2 Cloud Function `crearCheckoutSession(priceId)`:
  - Reutiliza o crea `stripeCustomerId` en `usuarios/{uid}`.
  - Devuelve URL de Stripe Checkout.
- [ ] 5.3 Cloud Function webhook `stripeWebhook` escuchando `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`:
  - Actualiza `usuarios/{uid}.plan` según `subscription.status`.
  - Verifica firma con `STRIPE_WEBHOOK_SECRET`.
- [ ] 5.4 Cloud Function `crearCustomerPortalSession()` para que el usuario gestione su suscripción.
- [ ] 5.5 Pantalla `CuentaScreen`: plan actual, uso del mes, botón "Gestionar suscripción" (portal) o "Upgradearme a Pro" (checkout).
- [ ] 5.6 Pantalla `UpgradeScreen` completa: comparativa Free vs Pro + CTA a Checkout.
- [ ] 5.7 Skill `stripe-mcp` o similar para poder auditar suscripciones sin dashboard manual.
- [ ] 5.8 Tests: webhook con firma inválida rechazado, simulación de upgrade y downgrade.

**Criterio de salida:** En modo test, Claude puede ejecutar el flujo completo: crear usuario, triggerear upgrade, webhook actualiza plan, usuario genera más de 5 recetas.

---

### Fase 6 — Deploy web + observabilidad  *(2–3 días)*

**Objetivo:** La app está en una URL pública estable, con previews por PR y métricas básicas.

- [ ] 6.1 Configurar Firebase Hosting channels: `live` (prod) y `staging`.
- [ ] 6.2 GitHub Actions workflow `deploy-web.yml`:
  - En merge a `main` → build + deploy a `live`.
  - En PR → build + deploy a preview channel efímero, comenta URL en el PR.
- [ ] 6.3 Configurar secrets (FIREBASE_TOKEN, OPENAI_API_KEY, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET) vía GitHub Secrets y `functions:secrets:set`.
- [ ] 6.4 Reglas de Firestore endurecidas revisadas con `firebase emulators:exec` en CI.
- [ ] 6.5 Logging estructurado en Functions (campo `event`, `uid`, `hogarId`, `costUsd`).
- [ ] 6.6 Dashboard básico en Firebase Console (metrics + Crashlytics web opcional).
- [ ] 6.7 Documento `SECURITY.md` con rotación de llaves y contacto.

**Criterio de salida:** `https://despensa-inteligente-c1f9d.web.app` funcional, dos miembros reales pueden usar la app completa.

---

### Fase 7 — Preparación Android + iOS para stores  *(al final, fuera del camino crítico web)*

**Objetivo:** Reactivar los targets móviles y dejar todo listo para publicar.

- [ ] 7.1 `flutter build apk` y `flutter build ipa` sin errores (el código multiplataforma no debería requerir cambios mayores, pero `mobile_scanner` y `go_router` deben comportarse bien en móvil).
- [ ] 7.2 Verificar permisos Android (`CAMERA`, `INTERNET`) en `android/app/src/main/AndroidManifest.xml`.
- [ ] 7.3 Verificar `ios/Runner/Info.plist` con `NSCameraUsageDescription`.
- [ ] 7.4 Iconos y splash via `flutter_launcher_icons` + `flutter_native_splash`.
- [ ] 7.5 Firmas: keystore Android (guardado en GitHub Secrets), certificados iOS + perfil de provisioning.
- [ ] 7.6 Configurar Play Console y App Store Connect (cuentas, fichas, pantallas).
- [ ] 7.7 Fastlane (opcional) o GitHub Actions con `google-github-actions/release-please-action` para builds internos.
- [ ] 7.8 Tracks iniciales: Internal Testing / TestFlight.

**Criterio de salida:** Build móvil publicado en pista interna de ambas stores.

---

## 3. Skills y MCPs a crear (bloque transversal)

Para que Claude pueda manejar producción, deploy y futuro release a stores sin intervención manual constante, se deben crear los siguientes skills/MCPs locales del proyecto (ubicados en `.claude/skills/` y `.claude/mcps/`). Se crean durante Fase 0 los básicos; los de billing y stores se crean justo antes de su fase correspondiente.

### 3.1 Skills (recetas de trabajo para Claude)

| Skill | Fase | Descripción |
|---|---|---|
| `despensa:flutter-ops` | 0 | Wrapper sobre comandos Flutter: `analyze`, `test`, `build web`, `build apk`, `build ipa`. Detecta errores y sugiere fixes conocidos (e.g. Dart SDK mismatch). |
| `despensa:firebase-ops` | 0 | Deploy de `hosting`, `functions`, `firestore:rules`, `firestore:indexes`. Ejecuta `firebase emulators:start` para tests locales. Sabe leer `firebase.json`. |
| `despensa:firestore-rules` | 1 | Verifica reglas con `firebase emulators:exec` + fixtures. Corre tests de seguridad antes de deploy. |
| `despensa:ai-prompt-lab` | 3 | Registra versiones de prompts del agente normalizador y del generador de recetas, con golden tests (input → output esperado). Evita regresiones al cambiar un prompt. |
| `despensa:plan-gate` | 4 | Inspecciona el estado de `usuarios/{uid}.aiUsage` y `plan`, útil para debug cuando un usuario reclama que le bloquearon. |
| `despensa:stripe-ops` | 5 | Lista suscripciones, clientes, webhooks; simula `checkout.session.completed` contra la Function local. |
| `despensa:deploy-web` | 6 | Skill maestro: pre-check (`analyze` + `test`) → `build web` → deploy preview o producción → smoke test contra la URL. |
| `despensa:release-android` | 7 | `build appbundle` + firmar + subir a Play Console (track internal). |
| `despensa:release-ios` | 7 | `build ipa` + firmar + subir a TestFlight via `altool` o Fastlane. |

### 3.2 MCPs a incluir (servidores que amplían las capacidades de Claude)

| MCP | Fase | Uso |
|---|---|---|
| `firebase-mcp` (oficial si existe, o wrapper sobre Firebase CLI) | 0 | Leer/escribir Firestore en dev, desplegar Functions, inspeccionar logs. |
| `openai-mcp` (o el MCP oficial de Anthropic que soporte OpenAI vía proxy) | 3 | Probar prompts del normalizador y del generador de recetas sin tocar la Function. |
| `stripe-mcp` | 5 | Listar suscripciones, crear sesiones de checkout de prueba, inspeccionar eventos de webhook. |
| `github-mcp` | 0 | Abrir PRs, comentar en PRs con la URL del preview, gestionar issues del plan. |
| `play-console-mcp` | 7 | Subir builds y gestionar tracks (si existe; alternativa: Fastlane). |
| `appstoreconnect-mcp` | 7 | TestFlight y submissions (si existe; alternativa: Fastlane). |

> **Nota:** Si un MCP específico no existe como paquete, se implementa un MCP mínimo local bajo `.claude/mcps/<nombre>/` usando el Claude MCP SDK. El plan de implementación de cada fase debe contemplar construirlo antes de usarlo.

---

## 4. Criterios de éxito global

La app se considera **funcional para web** cuando:

1. Dos usuarios reales se registran, crean/comparten un hogar, y ven la misma despensa.
2. Se pueden escanear códigos de barra en Chrome y la información se autocompleta.
3. Agregar un producto nuevo lo persiste en la DB global tras pasar por el agente IA.
4. Un segundo usuario con el mismo código obtiene los datos ya enriquecidos.
5. Se pueden generar recetas que priorizan productos próximos a vencer.
6. El plan Free bloquea al exceder 3 recetas/mes o 30 productos en despensa; el upgrade a Pro vía Stripe funciona y destrapa ambos límites (50 recetas / 300 productos).
7. La app está desplegada en `https://despensa-inteligente-c1f9d.web.app` con previews automáticos por PR.
8. CI corre `analyze` + `test` + `build web` en verde en `main`.

Las condiciones para móvil se declaran cumplidas cuando Fase 7 está lista y hay al menos un build en pista interna en ambas stores.

---

## 5. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| `mobile_scanner` con bugs en Flutter Web | Alto (Fase 3 depende de él) | Spike de 2 h en Fase 0 para validar; fallback a entrada manual + `html5-qrcode` vía interop. |
| Costos OpenAI descontrolados | Alto | Rate limit por plan + prompt caching + cache de recetas por hash de ingredientes + modelo barato (4o-mini) para normalización. |
| Reglas Firestore mal escritas → fuga entre hogares | Crítico | Tests de reglas obligatorios en CI antes de cada merge a `main`. |
| Webhook de Stripe en desarrollo local | Medio | Usar `stripe listen --forward-to localhost` durante Fase 5; CI usa modo test. |
| Usuario escribe datos basura en DB global | Medio-alto | Agente IA con umbral de confianza 0.8 + revisión humana en `pendiente_revision` + "voto mayoritario" para sobrescrituras. |
| Divergencia entre targets web y móvil | Medio | Mantener 100% de la lógica en `features/*` sin ramas por plataforma; solo separar en `services/` si es imprescindible. |
| Falta de datos iniciales en productos globales → UX pobre | Medio | Hidratación automática vía OpenFoodFacts antes de pedirle al usuario que llene. |

---

## 6. Calendario orientativo

| Fase | Duración estimada | Ventana |
|---|---|---|
| 0 | 1–2 días | Semana 1 |
| 1 | 3–4 días | Semana 1–2 |
| 2 | 3–4 días | Semana 2 |
| 3 | 6–8 días | Semana 3–4 |
| 4 | 4–5 días | Semana 4–5 |
| 5 | 4–5 días | Semana 5–6 |
| 6 | 2–3 días | Semana 6 |
| 7 | 4–6 días | Semana 7 (diferido) |

**Total estimado a web productiva:** ~6 semanas de trabajo efectivo.
**Total incluyendo preparación stores:** ~7 semanas.

---

## 7. Convenciones de trabajo

- **Branching:** `main` protegido; features en `feature/<fase-<n>>-<slug>` desde `develop`. PRs siempre revisadas, CI verde, preview desplegado.
- **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:`).
- **Tests mínimos antes de cerrar una fase:** unit tests del repositorio, widget tests de la pantalla principal, emulator tests de las Functions de la fase, regla Firestore cubriendo el caso multitenant.
- **Secretos:** nunca en el repo. `.env` para desarrollo, `firebase functions:secrets:set` en prod, GitHub Secrets en CI.
- **Actualización del plan:** cada PR que cierre una tarea marca el checkbox correspondiente en este archivo.

---

## 8. Plan de contenido — Build in public

**Objetivo:** usar el proceso de construcción como motor de marketing orgánico. Generar audiencia interesada en despensa/cocina/tecnología en Chile y LATAM, convertir espectadores en beta testers de la Fase 6 y en suscriptores Pro post-lanzamiento. **Secundario:** validar demanda de features por engagement antes de construirlas.

### 8.1 Plataformas y cadencia

| Plataforma | Formato | Cadencia |
|---|---|---|
| TikTok (principal) | Short vertical 15–60 s | 2–3 por semana |
| Instagram Reels | Espejo del TikTok | 2–3 por semana |
| YouTube Shorts | Espejo del TikTok | 2–3 por semana |
| YouTube long-form | Recap mensual 5–10 min | 1 por mes |
| Twitter/X | Hilo de avance semanal | 1 por semana |
| Newsletter (Substack o similar) | Recap largo | 1 por mes, desde Fase 2 |

Herramientas: grabación con OBS o el capture nativo de macOS; edición con CapCut o Descript; no se requiere estudio.

### 8.2 Red lines — lo que NO se muestra

Cosas que jamás aparecen en cámara, por defensa de IP o OPSEC del proceso:

- **Cualquier asistente de código con IA visible**: Claude Code, Cursor, Copilot, Windsurf, ChatGPT abierto para generar código — ni en CLI, ni en extensión, ni en una pestaña del navegador. La narrativa es "yo construyo", el cómo es privado.
- **Código fuente real en pantalla.** Si se necesita un shot de "estoy programando", usar B-roll genérico (manos sobre teclado, pantalla borrosa, editor con código dummy sin lógica de negocio).
- **Prompts literales** del agente normalizador, del generador de recetas, o cualquier otro componente IA.
- **Esquema real de Firestore** (nombres de colecciones/campos, reglas de seguridad, estructura de `productos_globales`).
- **La arquitectura del enriquecimiento cruzado de la DB global.** Este es el núcleo defensible del producto — mostrarlo literalmente regala la idea a cualquier dev que vea el video.
- **Decisiones de precio** en tiempo real hasta que estén fijas en Stripe producción.
- **Métricas de negocio reales** (MAU, revenue, conversion) hasta post-lanzamiento.
- **Credenciales, dashboards con datos, Firebase Console, GitHub Actions logs, emails de usuarios.**
- **Stack técnico detallado** (evitar decir "uso Firestore + Cloud Functions + Riverpod" — suficiente con "está hecho con Flutter para web y móvil").

### 8.3 Qué SÍ se muestra

- La app corriendo en el navegador — screen capture del resultado final.
- Mockups, pantallas terminadas, transiciones, micro-animaciones.
- El problema contado en primera persona: tú abriendo tu propia despensa, productos caducados, frustraciones reales con otras apps.
- UX decisions narradas ("por qué dark mode", "por qué ordeno por vencimiento y no alfabético").
- Historia del fundador: rutina de supermercado, por qué este producto, de dónde viene la idea.
- **Magic moments** grabados como reacción: primer login real, primer producto escaneado, primera receta generada, primer usuario real usándola.
- Testing con familia/amigos (con consentimiento) reaccionando a la UI.
- Comparativas honestas con apps existentes del mercado.
- Sprint recaps mensuales contados como "esto funciona ahora", nunca como "esto fue difícil de codear".
- "Detrás de cámaras" de la vida de un dev chileno construyendo un SaaS — sin mostrar el editor.

### 8.4 Contenido por fase

| Fase | Ángulo principal | Hook sugerido |
|---|---|---|
| 0 | "Arranco un proyecto nuevo, esta vez en público." | Compromiso vulnerable + call to follow |
| 1 | "Cómo comparto mi despensa con mi familia sin una hoja de cálculo." | Problem/solution personal |
| 2 | "Mi despensa me avisa antes de que algo caduque." | Magic moment visual con badges rojos/amarillos |
| 3 | "Escaneé 50 productos en 2 minutos — y la app ya sabía cuáles eran." | Speed demo del barcode |
| 4 | "Le pedí a una IA que cocinara con lo que se me va a echar a perder." | Hook IA + impacto ambiental (anti-desperdicio) |
| 5 | "Lanzamos el plan Pro." | Launch moment + CTA a suscribirse |
| 6 | "Ya está en vivo, pueden probarla gratis." | CTA real con link |
| 7 | "Estamos en Play Store y App Store." | Milestone, foto del listing |

### 8.5 Calendario transversal

- **Fase 0–1:** 1 short/semana. Todavía no hay mucho que mostrar; enfoque en "founder story" y teasers de mockups.
- **Fase 2–3:** 2–3 shorts/semana. Aparecen los magic moments (ordenamiento, scanner).
- **Fase 4–5:** 3 shorts/semana + primer long-form recap. Picks para el lanzamiento.
- **Fase 6 en adelante:** cadencia regular, ya con usuarios reales y testimonios.

### 8.6 Gestión operativa del contenido

- [ ] 8.6.1 Crear carpeta local `content/` **gitignoreada** con subcarpetas `raw/`, `editado/`, `thumbnails/`, `guiones/`. Nunca commitear material crudo al repo.
- [ ] 8.6.2 Mantener un backlog de guiones cortos en Notion o en `content/guiones/backlog.md` (local). Cada guión: hook, desarrollo, CTA, duración estimada, fase asociada.
- [ ] 8.6.3 Revisión de cada video antes de publicar con checklist de red lines (sección 8.2). Si aparece algo prohibido → no se publica.
- [ ] 8.6.4 Medir solo dos métricas mensuales: **seguidores netos** y **clicks a la landing / beta waitlist**. Ignorar vanity metrics.
- [ ] 8.6.5 Reservar 3–5 h/semana al bloque de contenido. Tratarlo como una fase paralela con deuda propia.

---

## 9. Próximos pasos inmediatos

Una vez aprobado este plan:

1. Invocar skill `superpowers:writing-plans` para descomponer **Fase 0** en un plan ejecutable (con tests y criterios por tarea).
2. Crear los skills `despensa:flutter-ops` y `despensa:firebase-ops`.
3. Arrancar la Fase 0 en una rama `feature/fase-0-fundaciones`.

---

*Plan sujeto a ajustes a medida que aparezca información nueva. Cualquier cambio estructural debe reflejarse aquí antes de empezar el trabajo.*
