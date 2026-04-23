import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/features/plan/data/flow_repository.dart';
import 'package:despensa_inteligente/features/plan/data/plan_providers.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen> {
  bool _loading = false;

  Future<void> _iniciarRegistroFlow() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final flowRepo = ref.read(flowRepositoryProvider);
      final result = await flowRepo.crearSuscripcion();
      if (!mounted) return;
      switch (result) {
        case FlowUrlOk(:final url):
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            _mostrarError('No se pudo abrir la página de registro');
          }
        case FlowError(:final message):
          _mostrarError('Error al iniciar el registro: $message');
      }
    } catch (e) {
      if (mounted) _mostrarError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Pro')),
      body: ResponsiveCenter(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.star, size: 72, color: Color(0xFFCDE600)),
            const SizedBox(height: 24),
            Text(
              'Desbloquea el Plan Pro',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const _BenefitTile(
              icon: Icons.auto_awesome,
              title: '50 recetas por mes',
              subtitle: 'vs 3 del plan Free',
            ),
            const _BenefitTile(
              icon: Icons.psychology,
              title: 'Gemini 2.5 Flash',
              subtitle: 'Modelo IA más potente para mejores recetas',
            ),
            const _BenefitTile(
              icon: Icons.inventory_2,
              title: '300 productos en despensa',
              subtitle: 'vs 30 del plan Free',
            ),
            const _BenefitTile(
              icon: Icons.home,
              title: 'Hasta 3 hogares',
              subtitle: 'Gestiona varias despensas',
            ),
            const _BenefitTile(
              icon: Icons.history,
              title: 'Historial completo de recetas',
              subtitle: 'Sin límite de historial',
            ),
            const SizedBox(height: 40),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              FilledButton.icon(
                key: const Key('btn_upgrade_pro'),
                onPressed: _iniciarRegistroFlow,
                icon: const Icon(Icons.star),
                label: const Text('Actualizar a Pro'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
            const SizedBox(height: 24),
            Text(
              'Al continuar serás redirigido a Flow para registrar tu tarjeta y activar la suscripción.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
