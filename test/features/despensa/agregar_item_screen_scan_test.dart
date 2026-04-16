// test/features/despensa/agregar_item_screen_scan_test.dart
import 'package:despensa_inteligente/features/auth/data/usuario_providers.dart';
import 'package:despensa_inteligente/features/auth/domain/usuario.dart';
import 'package:despensa_inteligente/features/despensa/presentation/agregar_item_screen.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_providers.dart';
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_repository.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:despensa_inteligente/services/firebase/firestore_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Noop implements CallableFn {
  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async => {};
}

class FakeRepo extends ProductosGlobalesRepository {
  FakeRepo()
      : super(
          lookupFn: _Noop(),
          proponerFn: _Noop(),
        );

  @override
  Future<LookupResult> lookupByBarcode(String barcode) async {
    return LookupFound(
      ProductoGlobal(
        barcode: barcode,
        nombre: 'Leche Soprole 1 L',
        marca: 'Soprole',
        categorias: const ['lacteos'],
        imagenUrl: null,
        nutricional: null,
        contribuidores: const ['u1'],
        camposFaltantes: const [],
        estado: 'publicado',
        source: 'user',
      ),
    );
  }

  @override
  Future<LookupResult> proponer({
    required String barcode,
    required String nombre,
    String? marca,
    List<String>? categorias,
    String? imagenUrl,
  }) async {
    return const LookupNotFound();
  }
}

void main() {
  testWidgets('barcode encontrado prefila nombre', (tester) async {
    final fakeFirestore = FakeFirebaseFirestore();
    await fakeFirestore
        .collection('hogares')
        .doc('h1')
        .set({'productosActivos': 0});

    final mockUsuario = Usuario(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Ana',
      plan: 'free',
      hogarActivo: 'h1',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          usuarioStreamProvider.overrideWith((_) => Stream.value(mockUsuario)),
          productosGlobalesRepositoryProvider.overrideWithValue(FakeRepo()),
        ],
        child: const MaterialApp(home: AgregarItemScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear código'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Ingresa el código de barras'),
        '7802800000000');
    await tester.tap(find.text('Usar'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Soprole 1 L'), findsOneWidget);
  });
}
