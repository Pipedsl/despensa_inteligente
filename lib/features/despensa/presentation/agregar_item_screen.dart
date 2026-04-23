import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/core/plan_config.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_repository.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/despensa/presentation/confirmar_pendiente_sheet.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_providers.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:despensa_inteligente/features/scanner/presentation/barcode_input.dart';

enum _ScanOutcome { found, notFound, pendingReview }

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
  String? _scannedBarcode;
  bool _loadingLookup = false;
  _ScanOutcome? _scanOutcome;

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
      // Fire-and-forget: proponer producto a la DB global si fue nuevo
      if (_scannedBarcode != null &&
          (_scanOutcome == _ScanOutcome.notFound ||
              _scanOutcome == _ScanOutcome.pendingReview)) {
        ref
            .read(productosGlobalesRepositoryProvider)
            .proponer(
              barcode: _scannedBarcode!,
              nombre: _nombreCtrl.text.trim(),
            )
            .catchError((Object e) {
          debugPrint('proponerProductoGlobal falló: $e');
          return const LookupNotFound() as LookupResult;
        });
      }
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

  Future<void> _abrirEscaner() async {
    String? barcode;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BarcodeInput(
        initialTab: BarcodeInputTab.keyboard,
        onBarcode: (bc) {
          barcode = bc;
          Navigator.pop(context);
        },
      ),
    );
    if (barcode == null || !mounted) return;
    setState(() => _loadingLookup = true);
    try {
      final repo = ref.read(productosGlobalesRepositoryProvider);
      final res = await repo.lookupByBarcode(barcode!);
      if (!mounted) return;
      switch (res) {
        case LookupFound(:final producto):
          _scannedBarcode = barcode;
          _nombreCtrl.text = producto.nombre;
          _scanOutcome = _ScanOutcome.found;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto encontrado')),
          );
        case LookupNotFound():
          _scannedBarcode = barcode;
          _scanOutcome = _ScanOutcome.notFound;
        case LookupPendingReview(:final sugerencia):
          final confirmada = await showConfirmarPendienteSheet(
            context,
            sugerencia: sugerencia,
          );
          if (confirmada == null || !mounted) return;
          _scannedBarcode = barcode;
          _nombreCtrl.text = confirmada.nombre;
          _scanOutcome = _ScanOutcome.pendingReview;
      }
    } finally {
      if (mounted) setState(() => _loadingLookup = false);
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
    final colorScheme = Theme.of(context).colorScheme;
    final nombreVacio = _nombreCtrl.text.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar ítem' : 'Agregar ítem')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: (nombreVacio || _guardando) ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ),
      ),
      body: ResponsiveCenter(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              // ── IDENTIFICACIÓN ──────────────────────────────────────
              _Section(
                titulo: 'IDENTIFICACIÓN',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadingLookup ? null : _abrirEscaner,
                      icon: _loadingLookup
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear código'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del producto'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                    if (_scanOutcome == _ScanOutcome.found) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        children: [
                          Chip(
                            avatar: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade300,
                            ),
                            label: const Text('Encontrado en la base'),
                            backgroundColor: Colors.green.shade900,
                            labelStyle: TextStyle(
                              color: Colors.green.shade200,
                              fontSize: 12,
                            ),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ],
                      ),
                    ] else if (_scanOutcome == _ScanOutcome.notFound) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        children: [
                          Chip(
                            avatar: Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: Colors.amber.shade300,
                            ),
                            label: const Text('Nuevo producto — se agregará a la base al guardar'),
                            backgroundColor: Colors.amber.shade900,
                            labelStyle: TextStyle(
                              color: Colors.amber.shade200,
                              fontSize: 12,
                            ),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── CANTIDAD ─────────────────────────────────────────────
              _Section(
                titulo: 'CANTIDAD',
                child: Row(
                  children: [
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
                      items: kUnidades
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unidad = v!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── VENCIMIENTO ──────────────────────────────────────────
              _Section(
                titulo: 'VENCIMIENTO',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.calendar_today,
                    color: _fechaVencimiento != null
                        ? const Color(0xffcde600)
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    _fechaVencimiento == null
                        ? 'Agregar fecha (opcional)'
                        : 'Vence: ${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}',
                    style: TextStyle(
                      color: _fechaVencimiento != null
                          ? const Color(0xffcde600)
                          : null,
                    ),
                  ),
                  trailing: _fechaVencimiento != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _fechaVencimiento = null),
                        )
                      : null,
                  onTap: _seleccionarFecha,
                ),
              ),
              const SizedBox(height: 20),

              // ── DETALLES OPCIONALES ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: const Text(
                    'DETALLES OPCIONALES',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget privado para bloques visuales agrupados del formulario.
class _Section extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Section({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    );
  }
}
