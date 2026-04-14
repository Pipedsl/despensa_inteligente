import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

class OnboardingHogarScreen extends ConsumerStatefulWidget {
  const OnboardingHogarScreen({super.key});

  @override
  ConsumerState<OnboardingHogarScreen> createState() =>
      _OnboardingHogarScreenState();
}

class _OnboardingHogarScreenState
    extends ConsumerState<OnboardingHogarScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _nameCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa un nombre para tu hogar');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uid =
          ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
      final hogar = await ref
          .read(hogarRepositoryProvider)
          .crear(nombre: nombre, ownerUid: uid);
      await ref
          .read(usuarioRepositoryProvider)
          .actualizarHogarActivo(uid, hogar.id);
      // El router redirigirá automáticamente al detectar hogarActivo
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Bienvenido!',
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Crea tu primer hogar para empezar a gestionar tu despensa.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nombre del hogar'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _crear,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Crear mi hogar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
