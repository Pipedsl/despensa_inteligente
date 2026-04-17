import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(usuarioStreamProvider);
    final nombre = usuarioAsync.asData?.value?.displayName ?? '';
    final hogar = usuarioAsync.asData?.value?.hogarActivo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DespensaInteligente'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Mis hogares',
            onPressed: () => context.push('/hogares'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nombre.isNotEmpty ? '¡Hola, $nombre!' : 'Bienvenido',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            if (hogar != null)
              Text(
                'Hogar activo: $hogar',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/despensa'),
              icon: const Icon(Icons.kitchen_outlined),
              label: const Text('Mi Despensa'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/recetas'),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Recetas'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
