import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';

class HogarRepository {
  final FirebaseFirestore _db;

  HogarRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('hogares');

  Future<Hogar> crear({
    required String nombre,
    required String ownerUid,
  }) async {
    final ref = _col.doc();
    final hogar = Hogar(
      id: ref.id,
      nombre: nombre,
      creadoPor: ownerUid,
      miembros: {ownerUid: 'owner'},
      miembrosIds: [ownerUid],
      productosActivos: 0,
      createdAt: DateTime.now(),
    );
    await ref.set(hogar.toMap());
    return hogar;
  }

  Future<List<Hogar>> listarPorUsuario(String uid) async {
    final query = await _col
        .where('miembrosIds', arrayContains: uid)
        .get();
    return query.docs.map(Hogar.fromFirestore).toList();
  }

  Stream<List<Hogar>> streamPorUsuario(String uid) {
    return _col
        .where('miembrosIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Hogar.fromFirestore).toList());
  }

  Future<Invitacion> generarInvitacion({
    required String hogarId,
    required String uid,
  }) async {
    final codigo = _generarCodigo();
    final invitacion = Invitacion(
      codigo: codigo,
      creadoPor: uid,
      expiraEn: DateTime.now().add(const Duration(hours: 24)),
      usadoPor: null,
    );
    await _col
        .doc(hogarId)
        .collection('invitaciones')
        .doc(codigo)
        .set(invitacion.toMap());
    return invitacion;
  }

  /// Busca el código en todos los hogares (collectionGroup query).
  Future<void> unirsePorCodigo({
    required String codigo,
    required String uid,
  }) async {
    final query = await _db
        .collectionGroup('invitaciones')
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Código de invitación no encontrado');
    }

    final invSnap = query.docs.first;
    final invitacion = Invitacion.fromFirestore(invSnap);

    if (!invitacion.estaVigente) {
      throw Exception('El código ha expirado o ya fue usado');
    }

    final hogarId = invSnap.reference.parent.parent!.id;

    await _db.runTransaction((tx) async {
      final hogarRef = _col.doc(hogarId);
      tx.update(hogarRef, {
        'miembros.$uid': 'member',
        'miembrosIds': FieldValue.arrayUnion([uid]),
      });
      tx.update(invSnap.reference, {'usadoPor': uid});
    });
  }

  String _generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

final hogarRepositoryProvider = Provider<HogarRepository>((ref) {
  return HogarRepository(ref.watch(firestoreProvider));
});
