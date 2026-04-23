import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/features/recetas/data/recetas_providers.dart';
import 'package:despensa_inteligente/features/recetas/data/recetas_repository.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';
import 'package:despensa_inteligente/features/plan/data/plan_providers.dart';
import 'package:despensa_inteligente/features/plan/domain/plan_config.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_providers.dart';

class RecetasScreen extends ConsumerStatefulWidget {
  const RecetasScreen({super.key});

  @override
  ConsumerState<RecetasScreen> createState() => _RecetasScreenState();
}

class _RecetasScreenState extends ConsumerState<RecetasScreen> {
  bool _generando = false;

  Future<void> _generarReceta(String hogarId) async {
    if (_generando) return;
    setState(() => _generando = true);
    try {
      final repo = ref.read(recetasRepositoryProvider);
      final result =
          await repo.generarReceta(hogarId: hogarId, preferencias: null);
      if (!mounted) return;
      switch (result) {
        case GenerarOk(:final fromCache):
          if (fromCache) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receta del historial reciente')),
            );
          }
          context.push('/recetas');
        case GenerarLimitExceeded():
          context.push('/upgrade');
        case GenerarDespensaVacia():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Agrega productos a tu despensa primero')),
          );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hogarId = ref.watch(hogarActivoIdProvider) ?? '';
    final planAsync = ref.watch(planConfigProvider);
    final recetasAsync = ref.watch(recetasListProvider(hogarId));

    final plan = planAsync.asData?.value ?? PlanConfig.free;

    return Scaffold(
      appBar: AppBar(title: const Text('Recetas')),
      body: ResponsiveCenter(
        maxWidth: ResponsiveCenter.listWidth,
        child: Column(
        children: [
          _CuotaBanner(plan: plan),
          Expanded(
            child: recetasAsync.when(
              data: (recetas) => recetas.isEmpty
                  ? const Center(child: Text('Aún no has generado recetas'))
                  : ListView.builder(
                      itemCount: recetas.length,
                      itemBuilder: (ctx, i) => _RecetaTile(receta: recetas[i]),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('btn_generar_receta'),
        onPressed: _generando ? null : () => _generarReceta(hogarId),
        icon: _generando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.auto_awesome),
        label: Text(_generando ? 'Generando...' : 'Generar receta'),
      ),
    );
  }
}

class _CuotaBanner extends StatelessWidget {
  final PlanConfig plan;
  const _CuotaBanner({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              plan.id == 'pro' ? Icons.star : Icons.star_border,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              plan.id == 'pro'
                  ? 'Plan Pro — ${plan.maxRecetasMes} recetas/mes'
                  : 'Plan Free — ${plan.maxRecetasMes} recetas/mes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecetaTile extends StatelessWidget {
  final Receta receta;
  const _RecetaTile({required this.receta});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.restaurant_menu),
      title: Text(receta.contenido.titulo),
      subtitle: Text(
        receta.ingredientesUsados.take(3).join(', ') +
            (receta.ingredientesUsados.length > 3 ? '...' : ''),
      ),
      trailing:
          receta.fromCache ? const Icon(Icons.cached, size: 16) : null,
      onTap: () =>
          context.push('/recetas/${receta.id}', extra: receta),
    );
  }
}
