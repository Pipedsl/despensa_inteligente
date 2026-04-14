import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_providers.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/despensa/presentation/despensa_screen.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_providers.dart';
import 'package:despensa_inteligente/features/hogares/domain/hogar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildScreen({
  List<ItemDespensa> items = const [],
  int productosActivos = 0,
  String plan = 'free',
}) {
  final now = DateTime.now();
  final mockHogar = Hogar(
    id: 'h1', nombre: 'Casa', creadoPor: 'u1',
    miembros: {'u1': 'owner'}, miembrosIds: ['u1'],
    productosActivos: productosActivos, createdAt: now,
  );
  final mockUsuario = Usuario(
    uid: 'u1', email: 'a@b.com', displayName: 'Ana',
    plan: plan, hogarActivo: 'h1', createdAt: now,
  );
  return ProviderScope(
    overrides: [
      despensaStreamProvider.overrideWith((_) => Stream.value(items)),
      hogarActivoStreamProvider.overrideWith((_) => Stream.value(mockHogar)),
      usuarioStreamProvider.overrideWith((_) => Stream.value(mockUsuario)),
    ],
    child: const MaterialApp(home: DespensaScreen()),
  );
}

void main() {
  final now = DateTime.now();

  testWidgets('muestra mensaje vacío cuando no hay ítems', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Tu despensa está vacía'), findsOneWidget);
  });

  testWidgets('muestra nombre del ítem', (tester) async {
    final items = [
      ItemDespensa(id: 'i1', nombre: 'Leche', cantidad: 1, unidad: 'L',
          agregadoPor: 'u1', estado: 'activo', createdAt: now, updatedAt: now),
    ];
    await tester.pumpWidget(buildScreen(items: items, productosActivos: 1));
    await tester.pumpAndSettle();
    expect(find.text('Leche'), findsOneWidget);
  });

  testWidgets('filtra ítems por texto', (tester) async {
    final items = [
      ItemDespensa(id: 'i1', nombre: 'Leche', cantidad: 1, unidad: 'L',
          agregadoPor: 'u1', estado: 'activo', createdAt: now, updatedAt: now),
      ItemDespensa(id: 'i2', nombre: 'Pan', cantidad: 2, unidad: 'unidades',
          agregadoPor: 'u1', estado: 'activo', createdAt: now, updatedAt: now),
    ];
    await tester.pumpWidget(buildScreen(items: items, productosActivos: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lec');
    await tester.pump();
    expect(find.text('Leche'), findsOneWidget);
    expect(find.text('Pan'), findsNothing);
  });

  testWidgets('muestra banner si hay ítems venciendo en ≤1 día', (tester) async {
    final items = [
      ItemDespensa(
        id: 'i1', nombre: 'Leche', cantidad: 1, unidad: 'L',
        fechaVencimiento: now.add(const Duration(hours: 20)),
        agregadoPor: 'u1', estado: 'activo', createdAt: now, updatedAt: now,
      ),
    ];
    await tester.pumpWidget(buildScreen(items: items, productosActivos: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('venciendo'), findsOneWidget);
  });

  testWidgets('muestra contador X / max en AppBar', (tester) async {
    await tester.pumpWidget(buildScreen(productosActivos: 5));
    await tester.pumpAndSettle();
    expect(find.textContaining('5 / 30'), findsOneWidget);
  });
}
