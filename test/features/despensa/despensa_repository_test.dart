import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late DespensaRepository repo;
  const hogarId = 'hogar1';
  const uid = 'uid1';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    repo = DespensaRepository(fakeFirestore);
    await fakeFirestore.collection('hogares').doc(hogarId).set({
      'nombre': 'Casa',
      'productosActivos': 0,
    });
  });

  group('agregar', () {
    test('crea documento y retorna ItemDespensa con id', () async {
      final item = await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
      );
      expect(item.id, isNotEmpty);
      expect(item.nombre, 'Leche');
      expect(item.estado, 'activo');
    });

    test('incrementa productosActivos en el hogar', () async {
      await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
      );
      final snap = await fakeFirestore.collection('hogares').doc(hogarId).get();
      expect(snap.data()!['productosActivos'], 1);
    });

    test('contador llega a 2 con dos productos', () async {
      await repo.agregar(hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30);
      await repo.agregar(hogarId: hogarId, nombre: 'Pan', cantidad: 2, unidad: 'unidades', uid: uid, maxProductos: 30);
      final snap = await fakeFirestore.collection('hogares').doc(hogarId).get();
      expect(snap.data()!['productosActivos'], 2);
    });

    test('lanza LimiteProductosException si productosActivos >= maxProductos', () async {
      await fakeFirestore.collection('hogares').doc(hogarId).update({'productosActivos': 30});
      expect(
        () => repo.agregar(
          hogarId: hogarId, nombre: 'Extra', cantidad: 1, unidad: 'unidades', uid: uid, maxProductos: 30,
        ),
        throwsA(isA<LimiteProductosException>()),
      );
    });
  });

  group('stream', () {
    test('retorna lista vacía inicialmente', () async {
      final items = await repo.stream(hogarId).first;
      expect(items, isEmpty);
    });

    test('retorna ítems activos ordenados por fechaVencimiento (nulls al final)', () async {
      final hoy = DateTime.now();
      await repo.agregar(
        hogarId: hogarId, nombre: 'Pan', cantidad: 1, unidad: 'unidades', uid: uid, maxProductos: 30,
        fechaVencimiento: hoy.add(const Duration(days: 10)),
      );
      await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
        fechaVencimiento: hoy.add(const Duration(days: 2)),
      );
      await repo.agregar(
        hogarId: hogarId, nombre: 'Arroz', cantidad: 1, unidad: 'kg', uid: uid, maxProductos: 30,
      );
      final items = await repo.stream(hogarId).first;
      expect(items[0].nombre, 'Leche');
      expect(items[1].nombre, 'Pan');
      expect(items[2].nombre, 'Arroz');
    });

    test('no incluye ítems consumidos', () async {
      final item = await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
      );
      await repo.marcarConsumido(hogarId: hogarId, itemId: item.id);
      final items = await repo.stream(hogarId).first;
      expect(items, isEmpty);
    });
  });

  group('eliminar', () {
    test('borra el documento y decrementa productosActivos', () async {
      final item = await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
      );
      await repo.eliminar(hogarId: hogarId, itemId: item.id);
      final items = await repo.stream(hogarId).first;
      expect(items, isEmpty);
      final snap = await fakeFirestore.collection('hogares').doc(hogarId).get();
      expect(snap.data()!['productosActivos'], 0);
    });
  });

  group('actualizar', () {
    test('actualiza campos sin cambiar productosActivos', () async {
      final item = await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
      );
      await repo.actualizar(hogarId: hogarId, item: item.copyWith(nombre: 'Leche Descremada', cantidad: 2));
      final items = await repo.stream(hogarId).first;
      expect(items.first.nombre, 'Leche Descremada');
      expect(items.first.cantidad, 2.0);
      final snap = await fakeFirestore.collection('hogares').doc(hogarId).get();
      expect(snap.data()!['productosActivos'], 1);
    });
  });

  group('marcarConsumido', () {
    test('cambia estado y decrementa productosActivos', () async {
      final item = await repo.agregar(
        hogarId: hogarId, nombre: 'Leche', cantidad: 1, unidad: 'L', uid: uid, maxProductos: 30,
      );
      await repo.marcarConsumido(hogarId: hogarId, itemId: item.id);
      final snap = await fakeFirestore.collection('hogares').doc(hogarId).get();
      expect(snap.data()!['productosActivos'], 0);
    });
  });
}
