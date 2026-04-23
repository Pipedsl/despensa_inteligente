import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/app/widgets/responsive_center.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:despensa_inteligente/services/auth.service.dart';

final _hogaresStreamProvider =
    StreamProvider.autoDispose<List<Hogar>>((ref) {
  final uid =
      ref.watch(firebaseAuthStateProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return ref.watch(hogarRepositoryProvider).streamPorUsuario(uid);
});

class MisHogaresScreen extends ConsumerStatefulWidget {
  const MisHogaresScreen({super.key});

  @override
  ConsumerState<MisHogaresScreen> createState() => _MisHogaresScreenState();
}

class _MisHogaresScreenState extends ConsumerState<MisHogaresScreen> {
  final _codigoCtrl = TextEditingController();
  final _nuevoNombreCtrl = TextEditingController();
  String? _invitacionActual;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nuevoNombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearHogar() async {
    final nombre = _nuevoNombreCtrl.text.trim();
    if (nombre.isEmpty) return;
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
      _nuevoNombreCtrl.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unirse() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    if (codigo.length != 6) {
      setState(() => _error = 'El código debe tener 6 caracteres');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid =
          ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
      await ref
          .read(hogarRepositoryProvider)
          .unirsePorCodigo(codigo: codigo, uid: uid);
      _codigoCtrl.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generarInvitacion(String hogarId) async {
    final uid =
        ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
    final inv = await ref
        .read(hogarRepositoryProvider)
        .generarInvitacion(hogarId: hogarId, uid: uid);
    setState(() => _invitacionActual = inv.codigo);
  }

  Future<void> _seleccionarHogar(String hogarId) async {
    final uid =
        ref.read(firebaseAuthStateProvider).asData?.value?.uid ?? '';
    await ref
        .read(usuarioRepositoryProvider)
        .actualizarHogarActivo(uid, hogarId);
  }

  @override
  Widget build(BuildContext context) {
    final hogaresAsync = ref.watch(_hogaresStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis hogares')),
      body: ResponsiveCenter(
        maxWidth: ResponsiveCenter.listWidth,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            Expanded(
              child: hogaresAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (hogares) => hogares.isEmpty
                    ? const Center(
                        child: Text('No perteneces a ningún hogar'))
                    : ListView.builder(
                        itemCount: hogares.length,
                        itemBuilder: (_, i) {
                          final h = hogares[i];
                          return Card(
                            child: ListTile(
                              title: Text(h.nombre),
                              subtitle: Text(
                                  '${h.miembrosIds.length} miembro(s)'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.share),
                                    tooltip: 'Generar código de invitación',
                                    onPressed: () =>
                                        _generarInvitacion(h.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.check_circle_outline),
                                    tooltip: 'Seleccionar como activo',
                                    onPressed: () =>
                                        _seleccionarHogar(h.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (_invitacionActual != null)
              Card(
                color: Colors.amber.shade900,
                child: ListTile(
                  title: Text(
                    'Código de invitación: $_invitacionActual',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  subtitle: const Text('Válido por 24 horas'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _invitacionActual!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Código copiado al portapapeles')),
                      );
                    },
                  ),
                ),
              ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Código de invitación'),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _unirse,
                  child: const Text('Unirme'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nuevoNombreCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nuevo hogar'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _crearHogar,
                  child: const Text('Crear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}
