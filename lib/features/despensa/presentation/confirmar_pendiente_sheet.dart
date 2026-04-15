// lib/features/despensa/presentation/confirmar_pendiente_sheet.dart
import 'package:flutter/material.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';

Future<SugerenciaNormalizador?> showConfirmarPendienteSheet(
  BuildContext context, {
  required SugerenciaNormalizador sugerencia,
}) {
  return showModalBottomSheet<SugerenciaNormalizador>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ConfirmarPendienteSheet(sugerencia: sugerencia),
  );
}

class _ConfirmarPendienteSheet extends StatefulWidget {
  final SugerenciaNormalizador sugerencia;
  const _ConfirmarPendienteSheet({required this.sugerencia});

  @override
  State<_ConfirmarPendienteSheet> createState() =>
      _ConfirmarPendienteSheetState();
}

class _ConfirmarPendienteSheetState extends State<_ConfirmarPendienteSheet> {
  late final TextEditingController _nombre;
  late final TextEditingController _marca;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.sugerencia.nombre);
    _marca = TextEditingController(text: widget.sugerencia.marca ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _marca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sugerencia;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confianza baja (${(s.confianza * 100).toStringAsFixed(0)}%)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _marca,
            decoration: const InputDecoration(labelText: 'Marca'),
          ),
          const SizedBox(height: 12),
          if (s.correcciones.isNotEmpty) ...[
            const Text('Correcciones aplicadas:'),
            const SizedBox(height: 4),
            ...s.correcciones.map(
              (c) => Row(
                children: [
                  const Text('• '),
                  Text(c),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  SugerenciaNormalizador(
                    nombre: _nombre.text.trim(),
                    marca: _marca.text.trim().isEmpty ? null : _marca.text.trim(),
                    categorias: s.categorias,
                    confianza: s.confianza,
                    correcciones: s.correcciones,
                  ),
                ),
                child: const Text('Confirmar'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
