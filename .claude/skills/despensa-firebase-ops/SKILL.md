---
name: despensa-firebase-ops
description: Operaciones Firebase para DespensaInteligente — emuladores, deploy de hosting/functions/firestore rules, logs. Úsalo cada vez que necesites interactuar con Firebase CLI sobre el proyecto despensa-inteligente-c1f9d.
---

# despensa-firebase-ops

Skill interno para operar la CLI de Firebase sobre el proyecto `despensa-inteligente-c1f9d`.

## Pre-requisitos

1. `firebase --version` debe funcionar.
2. El usuario ya corrió `firebase login` en esta máquina.
3. El proyecto activo es `despensa-inteligente-c1f9d` (verificar con `firebase use`).

Si alguno falla, detenerse y pedir al usuario que lo resuelva.

## Comandos canónicos

### Verificar proyecto activo
```bash
firebase use despensa-inteligente-c1f9d
```

### Emuladores (desarrollo local)
```bash
firebase emulators:start
```
Levanta Auth (9099), Firestore (8080), Functions (5001), Hosting (5000). UI en http://localhost:4000.

Para levanta solo algunos:
```bash
firebase emulators:start --only auth,firestore,functions
```

### Deploy — Hosting (web)
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

### Deploy completo
```bash
flutter build web --release && firebase deploy
```

### Logs de Functions
```bash
firebase functions:log --limit 50
```

### Secrets (se configuran una vez, no se commitean)
```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
```

## Flujo "deploy web" estándar

1. Correr `despensa-flutter-ops` (analyze + test + build web).
2. `firebase deploy --only hosting`.
3. Smoke test contra la URL live.

## Qué NO hace este skill

- No modifica `firebase_options.dart` (lo regenera `flutterfire configure`, que solo corre el usuario).
- No expone secretos en logs ni en código.
- No corre `firebase init` (puede pisar `firebase.json` — siempre editar a mano o via este skill).
