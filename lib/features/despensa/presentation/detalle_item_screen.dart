import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/app/widgets/form_section.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_repository.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_providers.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';

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

    // Watch producto lookup if barcode is available
    AsyncValue<LookupResult>? lookupAsync;
    if (item.barcode != null) {
      lookupAsync = ref.watch(productoLookupProvider(item.barcode!));
    }

    // Extract product data if lookup succeeded
    ProductoGlobal? producto;
    if (lookupAsync != null) {
      lookupAsync.whenData((result) {
        if (result is LookupFound) {
          producto = result.producto;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(item.nombre)),
      body: ResponsiveCenter(
        child: Padding(
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
            // Producto info section
            if (producto != null) ...[
              const SizedBox(height: 16),
              _ProductoSection(producto: producto!),
            ],
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
    if (!context.mounted) return;
    if (ok != true) return;
    final hogarId = ref.read(usuarioStreamProvider).asData?.value?.hogarActivo;
    if (hogarId == null) return;
    await ref.read(despensaRepositoryProvider).eliminar(hogarId: hogarId, itemId: item.id);
    if (context.mounted) context.pop();
  }
}

class _ProductoSection extends StatelessWidget {
  final ProductoGlobal producto;
  const _ProductoSection({required this.producto});

  @override
  Widget build(BuildContext context) {
    final nut = producto.nutricional;
    return FormSection(
      titulo: 'PRODUCTO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (producto.marca != null) _Row('Marca', producto.marca!),
          if (producto.categorias.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: producto.categorias
                  .map((c) => Chip(
                        label: Text(c, style: const TextStyle(fontSize: 11)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          if (nut != null) ...[
            const SizedBox(height: 12),
            const Text(
              'TABLA NUTRICIONAL',
              style: TextStyle(fontSize: 11, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            _NutGrid(nut: nut),
          ],
        ],
      ),
    );
  }
}

class _NutGrid extends StatelessWidget {
  final Nutricional nut;
  const _NutGrid({required this.nut});

  @override
  Widget build(BuildContext context) {
    final fields = <(String, double?)>[
      ('Energía (kcal)', nut.energiaKcal),
      ('Proteínas (g)', nut.proteinasG),
      ('Grasas totales (g)', nut.grasasG),
      ('Grasas saturadas (g)', nut.grasasSaturadasG),
      ('Carbohidratos (g)', nut.carbosG),
      ('Azúcares (g)', nut.azucaresG),
      ('Fibra (g)', nut.fibraG),
      ('Sodio (mg)', nut.sodioMg),
    ].where((f) => f.$2 != null).toList();

    if (fields.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final twoCols = constraints.maxWidth >= 300;
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: fields
            .map((f) => SizedBox(
                  width: twoCols
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          f.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        f.$2!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
    });
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
