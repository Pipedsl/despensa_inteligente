import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/app/widgets/form_section.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_providers.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';

const List<String> _kCategorias = [
  'Lácteos',
  'Carnes y pescados',
  'Frutas y verduras',
  'Panadería',
  'Bebidas',
  'Snacks',
  'Congelados',
  'Despensa seca',
  'Otros',
];

const List<String> _kUnidadesPorcion = ['g', 'ml'];

class ProponerProductoResult {
  final String nombre;
  final Nutricional? nutricional;
  const ProponerProductoResult({required this.nombre, this.nutricional});
}

class ProponerProductoScreen extends ConsumerStatefulWidget {
  final String barcode;
  const ProponerProductoScreen({super.key, required this.barcode});

  @override
  ConsumerState<ProponerProductoScreen> createState() =>
      _ProponerProductoScreenState();
}

class _ProponerProductoScreenState
    extends ConsumerState<ProponerProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _porcionCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinasCtrl = TextEditingController();
  final _grasasCtrl = TextEditingController();
  final _grasasSatCtrl = TextEditingController();
  final _carbosCtrl = TextEditingController();
  final _azucaresCtrl = TextEditingController();
  final _fibraCtrl = TextEditingController();
  final _sodioCtrl = TextEditingController();

  String _categoria = _kCategorias.last;
  String _unidadPorcion = 'g';
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _marcaCtrl.dispose();
    _porcionCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinasCtrl.dispose();
    _grasasCtrl.dispose();
    _grasasSatCtrl.dispose();
    _carbosCtrl.dispose();
    _azucaresCtrl.dispose();
    _fibraCtrl.dispose();
    _sodioCtrl.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  Nutricional _nutricional() => Nutricional(
        energiaKcal: _parse(_kcalCtrl),
        proteinasG: _parse(_proteinasCtrl),
        grasasG: _parse(_grasasCtrl),
        grasasSaturadasG: _parse(_grasasSatCtrl),
        carbosG: _parse(_carbosCtrl),
        azucaresG: _parse(_azucaresCtrl),
        fibraG: _parse(_fibraCtrl),
        sodioMg: _parse(_sodioCtrl),
        porcionG: _parse(_porcionCtrl),
      );

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final repo = ref.read(productosGlobalesRepositoryProvider);
      final nutricional = _nutricional();
      await repo.proponer(
        barcode: widget.barcode,
        nombre: _nombreCtrl.text.trim(),
        marca: _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
        categorias: [_categoria],
        nutricional:
            nutricional.toMap().isEmpty ? null : nutricional,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias! Tu aporte ayuda a la comunidad.'),
        ),
      );
      context.pop(ProponerProductoResult(
        nombre: _nombreCtrl.text.trim(),
        nutricional: nutricional.toMap().isEmpty ? null : nutricional,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aportar producto')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Agregar a la comunidad'),
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
              FormSection(
                titulo: 'IDENTIFICACIÓN',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Código de barras',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(widget.barcode),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _marcaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Marca (opcional)',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                      ),
                      items: _kCategorias
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _categoria = v ?? _categoria),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FormSection(
                titulo: 'PORCIÓN DE REFERENCIA',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _porcionCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Porción',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 84,
                          child: DropdownButtonFormField<String>(
                            initialValue: _unidadPorcion,
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                            ),
                            items: _kUnidadesPorcion
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(
                              () => _unidadPorcion = v ?? _unidadPorcion,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los valores nutricionales se refieren a esta porción.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FormSection(
                titulo: 'TABLA NUTRICIONAL (OPCIONAL)',
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final twoCols = constraints.maxWidth >= 360;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _nutField(
                            'Energía (kcal)', _kcalCtrl, twoCols, constraints),
                        _nutField(
                            'Proteínas (g)', _proteinasCtrl, twoCols, constraints),
                        _nutField(
                            'Grasas totales (g)', _grasasCtrl, twoCols, constraints),
                        _nutField(
                            'Grasas saturadas (g)', _grasasSatCtrl, twoCols, constraints),
                        _nutField(
                            'Carbohidratos (g)', _carbosCtrl, twoCols, constraints),
                        _nutField(
                            'Azúcares (g)', _azucaresCtrl, twoCols, constraints),
                        _nutField(
                            'Fibra (g)', _fibraCtrl, twoCols, constraints),
                        _nutField(
                            'Sodio (mg)', _sodioCtrl, twoCols, constraints),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutField(
    String label,
    TextEditingController ctrl,
    bool twoCols,
    BoxConstraints constraints,
  ) {
    final w = twoCols
        ? (constraints.maxWidth - 12) / 2
        : constraints.maxWidth;
    return SizedBox(
      width: w,
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
