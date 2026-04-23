import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';

class LimiteProductosException implements Exception {
  const LimiteProductosException();
  @override
  String toString() => 'Se alcanzó el límite de productos del plan.';
}

class DespensaRepository {
  final FirebaseFirestore _db;

  DespensaRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String hogarId) =>
      _db.collection('hogares').doc(hogarId).collection('despensa');

  DocumentReference<Map<String, dynamic>> _hogarRef(String hogarId) =>
      _db.collection('hogares').doc(hogarId);

  Stream<List<ItemDespensa>> stream(String hogarId) {
    return _col(hogarId)
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map((snap) {
      final items = snap.docs.map(ItemDespensa.fromFirestore).toList();
      items.sort((a, b) {
        if (a.fechaVencimiento == null && b.fechaVencimiento == null) return 0;
        if (a.fechaVencimiento == null) return 1;
        if (b.fechaVencimiento == null) return -1;
        return a.fechaVencimiento!.compareTo(b.fechaVencimiento!);
      });
      return items;
    });
  }

  Future<ItemDespensa> agregar({
    required String hogarId,
    required String nombre,
    required double cantidad,
    required String unidad,
    required String uid,
    required int maxProductos,
    DateTime? fechaVencimiento,
    DateTime? fechaCompra,
    double? precio,
    String? tienda,
    double? cantidadComprada,
    String? notas,
    String? barcode,
  }) async {
    final hogarSnap = await _hogarRef(hogarId).get();
    final productosActivos = hogarSnap.data()?['productosActivos'] as int? ?? 0;
    if (productosActivos >= maxProductos) throw const LimiteProductosException();

    final ref = _col(hogarId).doc();
    final now = DateTime.now();
    final item = ItemDespensa(
      id: ref.id,
      nombre: nombre,
      cantidad: cantidad,
      unidad: unidad,
      fechaVencimiento: fechaVencimiento,
      fechaCompra: fechaCompra,
      precio: precio,
      tienda: tienda,
      cantidadComprada: cantidadComprada,
      agregadoPor: uid,
      notas: notas,
      estado: 'activo',
      createdAt: now,
      updatedAt: now,
      barcode: barcode,
    );

    final batch = _db.batch();
    batch.set(ref, item.toMap());
    batch.update(_hogarRef(hogarId), {'productosActivos': FieldValue.increment(1)});
    await batch.commit();

    return item;
  }

  Future<void> actualizar({required String hogarId, required ItemDespensa item}) async {
    await _col(hogarId).doc(item.id).update({
      ...item.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> eliminar({required String hogarId, required String itemId}) async {
    final batch = _db.batch();
    batch.delete(_col(hogarId).doc(itemId));
    batch.update(_hogarRef(hogarId), {'productosActivos': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> marcarConsumido({required String hogarId, required String itemId}) async {
    final batch = _db.batch();
    batch.update(_col(hogarId).doc(itemId), {
      'estado': 'consumido',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    batch.update(_hogarRef(hogarId), {'productosActivos': FieldValue.increment(-1)});
    await batch.commit();
  }
}

final despensaRepositoryProvider = Provider<DespensaRepository>((ref) {
  return DespensaRepository(ref.watch(firestoreProvider));
});
