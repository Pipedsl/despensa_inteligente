import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Pro')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, size: 64, color: Color(0xFFCDE600)),
            const SizedBox(height: 24),
            Text(
              'Desbloquea el Plan Pro',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '50 recetas/mes · Gemini 2.5 Flash · 300 productos · '
              '3 hogares · Historial completo',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Próximamente — Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
