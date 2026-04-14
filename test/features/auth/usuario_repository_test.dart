import 'package:despensa_inteligente/features/auth/data/usuario_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UsuarioRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = UsuarioRepository(firestore);
  });

  group('UsuarioRepository', () {
    test('crear guarda el documento en /usuarios/{uid}', () async {
      await repo.crear(
        uid: 'uid1',
        email: 'a@b.cl',
        displayName: 'Ana',
      );

      final snap =
          await firestore.collection('usuarios').doc('uid1').get();
      expect(snap.exists, isTrue);
      expect(snap['email'], 'a@b.cl');
      expect(snap['plan'], 'free');
      expect(snap['hogarActivo'], isNull);
    });

    test('obtener retorna null si el documento no existe', () async {
      final result = await repo.obtener('uid_inexistente');
      expect(result, isNull);
    });

    test('obtener retorna el Usuario si existe', () async {
      await repo.crear(
          uid: 'uid2', email: 'b@c.cl', displayName: 'Beto');
      final result = await repo.obtener('uid2');

      expect(result, isNotNull);
      expect(result!.email, 'b@c.cl');
      expect(result.plan, 'free');
    });

    test('actualizarHogarActivo persiste el hogarId', () async {
      await repo.crear(uid: 'uid3', email: 'c@d.cl', displayName: 'Cata');
      await repo.actualizarHogarActivo('uid3', 'hogar_abc');

      final result = await repo.obtener('uid3');
      expect(result!.hogarActivo, 'hogar_abc');
    });

    test('crearSiNoExiste no sobrescribe un usuario existente', () async {
      await repo.crear(uid: 'uid4', email: 'orig@b.cl', displayName: 'Orig');
      await repo.crearSiNoExiste(
          uid: 'uid4', email: 'new@b.cl', displayName: 'New');

      final result = await repo.obtener('uid4');
      expect(result!.email, 'orig@b.cl');
    });
  });
}
