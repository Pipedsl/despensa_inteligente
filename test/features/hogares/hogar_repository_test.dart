import 'package:despensa_inteligente/features/hogares/data/hogar_repository.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HogarRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = HogarRepository(firestore);
  });

  group('HogarRepository', () {
    test('crear devuelve un Hogar con el creador como owner', () async {
      final hogar = await repo.crear(nombre: 'Mi Casa', ownerUid: 'uid1');

      expect(hogar.nombre, 'Mi Casa');
      expect(hogar.miembros['uid1'], 'owner');
      expect(hogar.miembrosIds, contains('uid1'));
    });

    test('listarPorUsuario retorna solo hogares del uid', () async {
      await repo.crear(nombre: 'Casa A', ownerUid: 'uid1');
      await repo.crear(nombre: 'Casa B', ownerUid: 'uid2');

      final lista = await repo.listarPorUsuario('uid1');
      expect(lista.length, 1);
      expect(lista.first.nombre, 'Casa A');
    });

    test('generarInvitacion crea una invitación vigente en la subcolección',
        () async {
      final hogar = await repo.crear(nombre: 'Casa Inv', ownerUid: 'uid1');
      final inv = await repo.generarInvitacion(hogarId: hogar.id, uid: 'uid1');

      expect(inv.codigo.length, 6);
      expect(inv.estaVigente, isTrue);

      final snap = await firestore
          .collection('hogares')
          .doc(hogar.id)
          .collection('invitaciones')
          .doc(inv.codigo)
          .get();
      expect(snap.exists, isTrue);
    });

    test('unirsePorCodigo agrega al usuario como member', () async {
      final hogar = await repo.crear(nombre: 'Casa Join', ownerUid: 'uid1');
      final inv = await repo.generarInvitacion(hogarId: hogar.id, uid: 'uid1');

      await repo.unirsePorCodigo(codigo: inv.codigo, uid: 'uid2');

      final snap = await firestore.collection('hogares').doc(hogar.id).get();
      final updated = Hogar.fromFirestore(snap);
      expect(updated.miembros['uid2'], 'member');
      expect(updated.miembrosIds, contains('uid2'));
    });

    test('unirsePorCodigo lanza excepción si el código no existe', () async {
      expect(
        () => repo.unirsePorCodigo(codigo: 'XXXXXX', uid: 'uid2'),
        throwsException,
      );
    });
  });
}
