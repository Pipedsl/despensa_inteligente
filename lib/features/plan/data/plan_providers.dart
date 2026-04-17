import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/plan/data/plan_repository.dart';
import 'package:despensa_inteligente/features/plan/domain/plan_config.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (_) => PlanRepository(),
);

final planConfigProvider = FutureProvider<PlanConfig>((ref) async {
  final usuarioAsync = ref.watch(usuarioStreamProvider);
  final usuario = usuarioAsync.asData?.value;
  if (usuario == null) return PlanConfig.free;
  final planId = usuario.plan;
  final repo = ref.read(planRepositoryProvider);
  return repo.getPlan(planId);
});
