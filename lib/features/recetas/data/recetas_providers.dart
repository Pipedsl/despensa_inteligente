import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/recetas/data/recetas_repository.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';
import 'package:despensa_inteligente/features/plan/data/plan_providers.dart';

final recetasRepositoryProvider = Provider<RecetasRepository>(
  (_) => RecetasRepository.firebase(),
);

final recetasListProvider = StreamProvider.family<List<Receta>, String>(
  (ref, hogarId) {
    final repo = ref.read(recetasRepositoryProvider);
    final plan = ref.watch(planConfigProvider).asData?.value;
    final limite = (plan?.historialCompleto ?? false)
        ? null
        : (plan?.historialLimite ?? 10);
    return repo.listarRecetas(hogarId, limite: limite);
  },
);
