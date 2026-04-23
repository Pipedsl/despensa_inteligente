// lib/features/hogares/data/hogar_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';

final hogarActivoStreamProvider = StreamProvider.autoDispose<Hogar?>((ref) {
  final hogarId = ref.watch(usuarioStreamProvider).asData?.value?.hogarActivo;
  if (hogarId == null) return Stream.value(null);
  return ref.watch(hogarRepositoryProvider).streamById(hogarId);
});

final hogarActivoIdProvider = Provider<String?>((ref) {
  return ref.watch(usuarioStreamProvider).asData?.value?.hogarActivo;
});
