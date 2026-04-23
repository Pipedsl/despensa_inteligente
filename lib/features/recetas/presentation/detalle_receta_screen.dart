import 'package:flutter/material.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';

class DetalleRecetaScreen extends StatelessWidget {
  final Receta receta;
  const DetalleRecetaScreen({super.key, required this.receta});

  @override
  Widget build(BuildContext context) {
    final contenido = receta.contenido;
    return Scaffold(
      appBar: AppBar(title: Text(contenido.titulo)),
      body: ResponsiveCenter(
        maxWidth: ResponsiveCenter.wideWidth,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            children: [
              Chip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text(contenido.tiempo),
              ),
              Chip(
                avatar: const Icon(Icons.people, size: 16),
                label: Text('${contenido.porciones} porciones'),
              ),
              if (receta.fromCache)
                const Chip(
                  avatar: Icon(Icons.cached, size: 16),
                  label: Text('Del historial'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Ingredientes usados',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...receta.ingredientesUsados.map(
            (nombre) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6),
                  const SizedBox(width: 8),
                  Text(nombre),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Preparación',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...contenido.pasos.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text('${entry.key + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
