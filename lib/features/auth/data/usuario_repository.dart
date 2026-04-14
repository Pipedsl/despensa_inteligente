import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';

class UsuarioRepository {
  final FirebaseFirestore _db;

  UsuarioRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('usuarios');

  Future<void> crear({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final usuario = Usuario(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      plan: 'free',
      hogarActivo: null,
      createdAt: DateTime.now(),
    );
    await _col.doc(uid).set(usuario.toMap());
  }

  Future<void> crearSiNoExiste({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) {
      await crear(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl);
    }
  }

  Future<Usuario?> obtener(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return Usuario.fromFirestore(snap);
  }

  Stream<Usuario?> stream(String uid) {
    return _col.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Usuario.fromFirestore(snap);
    });
  }

  Future<void> actualizarHogarActivo(String uid, String hogarId) async {
    await _col.doc(uid).update({'hogarActivo': hogarId});
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  return UsuarioRepository(ref.watch(firestoreProvider));
});
