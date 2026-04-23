import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/features/despensa/data/despensa_providers.dart';
import 'package:despensa_inteligente/features/despensa/domain/item_despensa.dart';
import 'package:despensa_inteligente/features/despensa/presentation/detalle_item_screen.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_providers.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();
  final mockItem = ItemDespensa(
    id: 'i1', nombre: 'Leche', cantidad: 1.5, unidad: 'L',
    precio: 990, tienda: 'Jumbo', notas: 'Descremada',
    agregadoPor: 'u1', estado: 'activo', createdAt: now, updatedAt: now,
  );
  final mockUsuario = Usuario(
    uid: 'u1', email: 'a@b.com', displayName: 'Ana',
    plan: 'free', hogarActivo: 'h1', createdAt: now,
  );

  Widget buildScreen() => ProviderScope(
        overrides: [
          despensaStreamProvider.overrideWith((_) => Stream.value([mockItem])),
          usuarioStreamProvider.overrideWith((_) => Stream.value(mockUsuario)),
        ],
        child: const MaterialApp(home: DetalleItemScreen(itemId: 'i1')),
      );

  testWidgets('muestra nombre, cantidad, tienda y notas', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Leche'), findsOneWidget);
    expect(find.textContaining('1.5'), findsOneWidget);
    expect(find.textContaining('Jumbo'), findsOneWidget);
    expect(find.textContaining('Descremada'), findsOneWidget);
  });

  testWidgets('tiene botones Editar, Eliminar y Consumido', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.text('Consumido'), findsOneWidget);
  });

  testWidgets('muestra tabla nutricional si el producto existe en base comunitaria',
      (tester) async {
    final mockItemConBarcode = ItemDespensa(
      id: 'i2',
      nombre: 'Leche Soprole',
      cantidad: 1,
      unidad: 'L',
      agregadoPor: 'u1',
      estado: 'activo',
      createdAt: now,
      updatedAt: now,
      barcode: '7802800000001',
    );
    final mockProducto = ProductoGlobal(
      barcode: '7802800000001',
      nombre: 'Leche Soprole 1 L',
      marca: 'Soprole',
      categorias: const ['Lácteos'],
      imagenUrl: null,
      nutricional: const Nutricional(
        energiaKcal: 61,
        proteinasG: 3.2,
        grasasG: 3.1,
        carbosG: 4.8,
        sodioMg: 45,
      ),
      contribuidores: const [],
      camposFaltantes: const [],
      estado: 'publicado',
      source: 'user',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          despensaStreamProvider.overrideWith(
              (_) => Stream.value([mockItemConBarcode])),
          usuarioStreamProvider.overrideWith((_) => Stream.value(mockUsuario)),
          productoLookupProvider('7802800000001').overrideWith(
            (_) async => LookupFound(mockProducto),
          ),
        ],
        child: const MaterialApp(home: DetalleItemScreen(itemId: 'i2')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PRODUCTO'), findsOneWidget);
    expect(find.text('Soprole'), findsAtLeastNWidgets(1));
    expect(find.text('Lácteos'), findsOneWidget);
    expect(find.text('TABLA NUTRICIONAL'), findsOneWidget);
    expect(find.textContaining('Energía'), findsOneWidget);
  });
}
