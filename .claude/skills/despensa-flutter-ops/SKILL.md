---
name: despensa-flutter-ops
description: Operaciones de desarrollo Flutter para DespensaInteligente — analyze, test, build web, build apk. Úsalo cada vez que necesites validar código Flutter antes de commitear o preparar un build.
---

# despensa-flutter-ops

Skill interno del proyecto DespensaInteligente para operar la CLI de Flutter de forma consistente.

## Cuándo usar este skill

- Antes de commitear cualquier cambio en `lib/` o `test/`.
- Antes de abrir un PR.
- Cuando el usuario pide "valida", "build", "analiza", "testea".
- Cuando un subagente termina una tarea de Flutter y debe confirmar que no rompió nada.

## Comandos canónicos

Todos se ejecutan desde la raíz del repo (`/Users/felipenavarretenavarrete/Desktop/proyectosWebiados/despensa_inteligente`).

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
Criterio: termina con `✓ Built build/web` o equivalente. Output en `build/web/`.

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
- **`No Firebase App '[DEFAULT]'`** en tests → asegurarse de que los providers de Firebase no se evalúen en `build()`. Usar lazy evaluation (mover `ref.read` dentro de callbacks).

## Qué NO hace este skill

- No hace deploy (eso es `despensa-firebase-ops`).
- No toca `pubspec.yaml` sin confirmación explícita.
- No ejecuta `flutter clean` salvo que el usuario lo pida.
