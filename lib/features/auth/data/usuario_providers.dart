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
