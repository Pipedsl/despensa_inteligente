import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hogar', () {
    test('fromFirestore parsea miembros correctamente', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('hogares').doc('h1').set({
        'nombre': 'Casa Felipe',
        'creadoPor': 'uid1',
        'miembros': {'uid1': 'owner', 'uid2': 'member'},
        'miembrosIds': ['uid1', 'uid2'],
        'productosActivos': 0,
        'createdAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      });

      final snap = await firestore.collection('hogares').doc('h1').get();
      final hogar = Hogar.fromFirestore(snap);

      expect(hogar.id, 'h1');
      expect(hogar.nombre, 'Casa Felipe');
      expect(hogar.miembros['uid1'], 'owner');
      expect(hogar.miembrosIds, contains('uid2'));
    });

    test('esOwner retorna true para el creador', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('hogares').doc('h2').set({
        'nombre': 'Test',
        'creadoPor': 'uid1',
        'miembros': {'uid1': 'owner'},
        'miembrosIds': ['uid1'],
        'productosActivos': 0,
        'createdAt': 0,
      });
      final snap = await firestore.collection('hogares').doc('h2').get();
      final hogar = Hogar.fromFirestore(snap);

      expect(hogar.esOwner('uid1'), isTrue);
      expect(hogar.esOwner('uid2'), isFalse);
    });
  });

  group('Invitacion', () {
    test('estaVigente retorna false si expiró', () {
      final invitacion = Invitacion(
        codigo: 'ABC123',
        creadoPor: 'uid1',
        expiraEn: DateTime.now().subtract(const Duration(hours: 1)),
        usadoPor: null,
      );
      expect(invitacion.estaVigente, isFalse);
    });

    test('estaVigente retorna true si no expiró', () {
      final invitacion = Invitacion(
        codigo: 'XYZ789',
        creadoPor: 'uid1',
        expiraEn: DateTime.now().add(const Duration(hours: 23)),
        usadoPor: null,
      );
      expect(invitacion.estaVigente, isTrue);
    });
  });
}
