import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_repository.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';

class DetalleItemScreen extends ConsumerWidget {
  final String itemId;
  const DetalleItemScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref
        .watch(despensaStreamProvider)
        .asData
        ?.value
        .where((i) => i.id == itemId)
        .firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(item.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row('Cantidad', '${item.cantidad} ${item.unidad}'),
            if (item.precio != null)
              _Row('Precio', '\$${item.precio!.toStringAsFixed(0)} ${item.moneda}'),
            if (item.tienda != null) _Row('Tienda', item.tienda!),
            if (item.fechaVencimiento != null)
              _Row('Vence',
                  '${item.fechaVencimiento!.day}/${item.fechaVencimiento!.month}/${item.fechaVencimiento!.year}'),
            if (item.notas != null) _Row('Notas', item.notas!),
            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/despensa/agregar', extra: item),
                  child: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _consumir(context, ref, item),
                  child: const Text('Consumido'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _eliminar(context, ref, item),
                child: const Text('Eliminar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _consumir(BuildContext context, WidgetRef ref, ItemDespensa item) async {
    final hogarId = ref.read(usuarioStreamProvider).asData?.value?.hogarActivo;
    if (hogarId == null) return;
    await ref.read(despensaRepositoryProvider).marcarConsumido(hogarId: hogarId, itemId: item.id);
    if (context.mounted) context.pop();
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, ItemDespensa item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar ítem'),
        content: Text('¿Seguro que querés eliminar "${item.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    final hogarId = ref.read(usuarioStreamProvider).asData?.value?.hogarActivo;
    if (hogarId == null) return;
    await ref.read(despensaRepositoryProvider).eliminar(hogarId: hogarId, itemId: item.id);
    if (context.mounted) context.pop();
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ]),
    );
  }
}
