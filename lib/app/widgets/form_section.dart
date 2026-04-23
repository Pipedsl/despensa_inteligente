import 'package:flutter/material.dart';

/// Bloque visual agrupado para formularios. Título en mayúsculas arriba,
/// contenido en un container elevado con bordes redondeados.
///
/// Uso:
/// ```dart
/// FormSection(
///   titulo: 'IDENTIFICACIÓN',
///   child: Column(children: [...]),
/// )
/// ```
class FormSection extends StatelessWidget {
  final String titulo;
  final Widget child;

  const FormSection({
    super.key,
    required this.titulo,
    required this.child,
  });

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
