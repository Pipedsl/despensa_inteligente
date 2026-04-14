import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/despensa/presentation/agregar_item_screen.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore.collection('hogares').doc('h1').set({'productosActivos': 0});
  });

  final mockUsuario = Usuario(
    uid: 'u1', email: 'a@b.com', displayName: 'Ana',
    plan: 'free', hogarActivo: 'h1', createdAt: DateTime.now(),
  );

  Widget buildScreen({ItemDespensa? item}) => ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          usuarioStreamProvider.overrideWith((_) => Stream.value(mockUsuario)),
        ],
        child: MaterialApp(home: AgregarItemScreen(item: item)),
      );

  testWidgets('botón Guardar deshabilitado si nombre está vacío', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'));
    expect(button.onPressed, isNull);
  });

  testWidgets('botón Guardar habilitado tras ingresar nombre', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre del producto'), 'Leche');
    await tester.pump();
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('modo edición muestra título "Editar ítem"', (tester) async {
    final item = ItemDespensa(
      id: 'i1', nombre: 'Leche', cantidad: 1, unidad: 'L',
      agregadoPor: 'u1', estado: 'activo',
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    await tester.pumpWidget(buildScreen(item: item));
    await tester.pumpAndSettle();
    expect(find.text('Editar ítem'), findsOneWidget);
  });

  testWidgets('modo crear muestra título "Agregar ítem"', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Agregar ítem'), findsOneWidget);
  });
}
