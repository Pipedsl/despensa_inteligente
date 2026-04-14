import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/core/plan_config.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_repository.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';

class AgregarItemScreen extends ConsumerStatefulWidget {
  final ItemDespensa? item; // null = crear, non-null = editar
  const AgregarItemScreen({super.key, this.item});

  @override
  ConsumerState<AgregarItemScreen> createState() => _AgregarItemScreenState();
}

class _AgregarItemScreenState extends ConsumerState<AgregarItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _tiendaCtrl;
  late final TextEditingController _notasCtrl;
  late String _unidad;
  DateTime? _fechaVencimiento;
  bool _guardando = false;

  bool get _esEdicion => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nombreCtrl = TextEditingController(text: i?.nombre ?? '');
    _cantidadCtrl = TextEditingController(text: i?.cantidad.toString() ?? '1');
    _precioCtrl = TextEditingController(text: i?.precio?.toString() ?? '');
    _tiendaCtrl = TextEditingController(text: i?.tienda ?? '');
    _notasCtrl = TextEditingController(text: i?.notas ?? '');
    _unidad = i?.unidad ?? 'unidades';
    _fechaVencimiento = i?.fechaVencimiento;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _tiendaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final usuario = ref.read(usuarioStreamProvider).asData?.value;
      final hogarId = usuario?.hogarActivo;
      if (usuario == null || hogarId == null) return;
      final repo = ref.read(despensaRepositoryProvider);

      if (_esEdicion) {
        await repo.actualizar(
          hogarId: hogarId,
          item: widget.item!.copyWith(
            nombre: _nombreCtrl.text.trim(),
            cantidad: double.tryParse(_cantidadCtrl.text) ?? 1,
            unidad: _unidad,
            fechaVencimiento: _fechaVencimiento,
            precio: double.tryParse(_precioCtrl.text),
            tienda: _tiendaCtrl.text.trim().isEmpty ? null : _tiendaCtrl.text.trim(),
            notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
          ),
        );
      } else {
        await repo.agregar(
          hogarId: hogarId,
          nombre: _nombreCtrl.text.trim(),
          cantidad: double.tryParse(_cantidadCtrl.text) ?? 1,
          unidad: _unidad,
          uid: usuario.uid,
          maxProductos: maxProductosParaPlan(usuario.plan),
          fechaVencimiento: _fechaVencimiento,
          precio: double.tryParse(_precioCtrl.text),
          tienda: _tiendaCtrl.text.trim().isEmpty ? null : _tiendaCtrl.text.trim(),
          notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        );
      }
      if (mounted) context.pop();
    } on LimiteProductosException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Límite de productos alcanzado. Actualizá tu plan para agregar más.'),
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _fechaVencimiento = picked);
  }

  @override
  Widget build(BuildContext context) {
    final nombreVacio = _nombreCtrl.text.trim().isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar ítem' : 'Agregar ítem')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del producto'),
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _cantidadCtrl,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _unidad,
                items: kUnidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unidad = v!),
              ),
            ]),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_fechaVencimiento == null
                  ? 'Fecha de vencimiento (opcional)'
                  : 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.calendar_today), onPressed: _seleccionarFecha),
                if (_fechaVencimiento != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _fechaVencimiento = null),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precioCtrl,
              decoration: const InputDecoration(labelText: 'Precio en CLP (opcional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tiendaCtrl,
              decoration: const InputDecoration(labelText: 'Tienda (opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasCtrl,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (nombreVacio || _guardando) ? null : _guardar,
              child: _guardando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
