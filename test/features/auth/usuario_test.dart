import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Usuario', () {
    test('fromFirestore parsea correctamente los campos', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('usuarios').doc('uid123').set({
        'email': 'test@test.cl',
        'displayName': 'Felipe',
        'plan': 'free',
        'hogarActivo': null,
        'createdAt': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      });

      final snap =
          await firestore.collection('usuarios').doc('uid123').get();
      final usuario = Usuario.fromFirestore(snap);

      expect(usuario.uid, 'uid123');
      expect(usuario.email, 'test@test.cl');
      expect(usuario.plan, 'free');
      expect(usuario.hogarActivo, isNull);
    });

    test('toMap incluye todos los campos requeridos', () {
      final usuario = Usuario(
        uid: 'uid1',
        email: 'a@b.cl',
        displayName: 'Ana',
        plan: 'free',
        hogarActivo: null,
        createdAt: DateTime(2026, 1, 1),
      );

      final map = usuario.toMap();
      expect(map['email'], 'a@b.cl');
      expect(map['plan'], 'free');
      expect(map.containsKey('createdAt'), isTrue);
    });
  });
}
