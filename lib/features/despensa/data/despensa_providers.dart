// lib/features/despensa/data/despensa_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_repository.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';

final despensaStreamProvider = StreamProvider.autoDispose<List<ItemDespensa>>((ref) {
  final hogarId = ref.watch(usuarioStreamProvider).asData?.value?.hogarActivo;
  if (hogarId == null) return Stream.value([]);
  return ref.watch(despensaRepositoryProvider).stream(hogarId);
});
