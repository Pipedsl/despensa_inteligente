import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/core/plan_config.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_providers.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_providers.dart';

class DespensaScreen extends ConsumerStatefulWidget {
  const DespensaScreen({super.key});

  @override
  ConsumerState<DespensaScreen> createState() => _DespensaScreenState();
}

class _DespensaScreenState extends ConsumerState<DespensaScreen> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(despensaStreamProvider);
    final hogar = ref.watch(hogarActivoStreamProvider).asData?.value;
    final plan = ref.watch(usuarioStreamProvider).asData?.value?.plan ?? 'free';

    final maxProductos = maxProductosParaPlan(plan);
    final productosActivos = hogar?.productosActivos ?? 0;
    final items = itemsAsync.asData?.value ?? [];
    final filtrados = _filtro.isEmpty
        ? items
        : items.where((i) => i.nombre.toLowerCase().contains(_filtro.toLowerCase())).toList();
    final hayVencimientos = items.any((i) => i.venceProximamente);

    return Scaffold(
      appBar: AppBar(
        title: Text('Despensa  $productosActivos / $maxProductos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/despensa/agregar'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (hayVencimientos)
            MaterialBanner(
              content: const Text('Hay productos venciendo pronto'),
              leading: const Icon(Icons.warning_amber, color: Colors.amber),
              actions: [
                TextButton(onPressed: () {}, child: const Text('OK')),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Filtrar por nombre...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filtro = v),
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) => filtrados.isEmpty
                  ? const Center(child: Text('Tu despensa está vacía'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(despensaStreamProvider),
                      child: ListView.builder(
                        itemCount: filtrados.length,
                        itemBuilder: (_, i) => _ItemTile(item: filtrados[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/despensa/agregar'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ItemDespensa item;
  const _ItemTile({required this.item});

  Color get _badgeColor => switch (item.estadoVencimiento) {
        EstadoVencimiento.vencido => Colors.red.shade900,
        EstadoVencimiento.urgente => Colors.red,
        EstadoVencimiento.porVencer => Colors.amber,
        EstadoVencimiento.ok => Colors.green,
        EstadoVencimiento.sinFecha => Colors.grey,
      };

  String get _badgeLabel {
    final dias = item.diasParaVencer;
    if (dias == null) return '';
    if (dias < 0) return 'Vencido';
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Mañana';
    return 'En $dias días';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.nombre),
      subtitle: Text('${item.cantidad} ${item.unidad}'),
      trailing: item.fechaVencimiento != null
          ? Chip(
              label: Text(
                _badgeLabel,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              backgroundColor: _badgeColor,
              padding: EdgeInsets.zero,
            )
          : null,
      onTap: () => context.push('/despensa/${item.id}'),
    );
  }
}
