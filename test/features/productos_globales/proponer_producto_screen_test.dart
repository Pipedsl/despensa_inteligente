import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_providers.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_repository.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:despensa_inteligente/features/productos_globales/presentation/proponer_producto_screen.dart';

class _FakeRepo implements ProductosGlobalesRepository {
  Map<String, dynamic>? lastDraft;

  @override
  CallableFn get lookupFn => throw UnimplementedError();

  @override
  CallableFn get proponerFn => throw UnimplementedError();

  @override
  Future<LookupResult> lookupByBarcode(String barcode) async =>
      const LookupNotFound();

  @override
  Future<LookupResult> proponer({
    required String barcode,
    required String nombre,
    String? marca,
    List<String>? categorias,
    String? imagenUrl,
    Nutricional? nutricional,
  }) async {
    lastDraft = {
      'barcode': barcode,
      'nombre': nombre,
      'marca': marca,
      'categorias': categorias,
      'nutricional': nutricional?.toMap(),
    };
    return const LookupNotFound();
  }
}

void main() {
  testWidgets('ProponerProductoScreen renderiza campos principales',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productosGlobalesRepositoryProvider.overrideWith((_) => _FakeRepo()),
        ],
        child: const MaterialApp(
          home: ProponerProductoScreen(barcode: '7802800000000'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Arriba del scroll: identificación y barcode
    expect(find.text('IDENTIFICACIÓN'), findsOneWidget);
    expect(find.text('7802800000000'), findsOneWidget);
    expect(find.text('Nombre del producto'), findsOneWidget);
    expect(find.text('Marca (opcional)'), findsOneWidget);
    expect(find.text('Categoría'), findsOneWidget);
    expect(find.text('Agregar a la comunidad'), findsOneWidget);

    // Scroll hasta la tabla nutricional
    await tester.scrollUntilVisible(
      find.text('TABLA NUTRICIONAL (OPCIONAL)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('PORCIÓN DE REFERENCIA'), findsOneWidget);
    expect(find.text('TABLA NUTRICIONAL (OPCIONAL)'), findsOneWidget);
    expect(find.text('Energía (kcal)'), findsOneWidget);
    expect(find.text('Sodio (mg)'), findsOneWidget);
  });

  testWidgets('submit con nombre vacío muestra validación',
      (tester) async {
    final fakeRepo = _FakeRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productosGlobalesRepositoryProvider.overrideWith((_) => fakeRepo),
        ],
        child: const MaterialApp(
          home: ProponerProductoScreen(barcode: '1234'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar a la comunidad'));
    await tester.pumpAndSettle();

    expect(find.text('Requerido'), findsOneWidget);
    expect(fakeRepo.lastDraft, isNull); // no se envió nada
  });
}
