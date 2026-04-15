// test/features/productos_globales/producto_global_test.dart
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductoGlobal.fromMap', () {
    test('parsea documento completo', () {
      final p = ProductoGlobal.fromMap({
        'barcode': '7802800000000',
        'nombre': 'Leche Soprole 1 L',
        'marca': 'Soprole',
        'categorias': ['lacteos'],
        'imagenUrl': null,
        'nutricional': null,
        'contribuidores': ['u1'],
        'camposFaltantes': ['imagenUrl', 'nutricional'],
        'estado': 'publicado',
        'source': 'user',
      });
      expect(p.nombre, 'Leche Soprole 1 L');
      expect(p.categorias, ['lacteos']);
      expect(p.estado, 'publicado');
    });

    test('tolera campos nulos', () {
      final p = ProductoGlobal.fromMap({
        'barcode': '1',
        'nombre': 'X',
        'marca': null,
        'categorias': <String>[],
        'imagenUrl': null,
        'nutricional': null,
        'contribuidores': <String>[],
        'camposFaltantes': <String>[],
        'estado': 'pendiente_revision',
        'source': 'user',
      });
      expect(p.marca, isNull);
      expect(p.nutricional, isNull);
    });
  });

  group('LookupResult.fromMap', () {
    test('status found con producto', () {
      final r = LookupResult.fromMap({
        'status': 'found',
        'producto': {
          'barcode': '1',
          'nombre': 'Leche',
          'marca': 'Soprole',
          'categorias': ['lacteos'],
          'imagenUrl': null,
          'nutricional': null,
          'contribuidores': ['u1'],
          'camposFaltantes': <String>[],
          'estado': 'publicado',
          'source': 'user',
        },
      });
      expect(r, isA<LookupFound>());
      expect((r as LookupFound).producto.nombre, 'Leche');
    });

    test('status not_found', () {
      final r = LookupResult.fromMap({'status': 'not_found'});
      expect(r, isA<LookupNotFound>());
    });

    test('status pending_review con sugerencia', () {
      final r = LookupResult.fromMap({
        'status': 'pending_review',
        'draftId': 'd1',
        'sugerencia': {
          'nombre': 'Leche',
          'marca': null,
          'categorias': ['lacteos'],
          'confianza': 0.6,
          'correcciones': <String>[],
        },
      });
      expect(r, isA<LookupPendingReview>());
      expect((r as LookupPendingReview).sugerencia.confianza, 0.6);
    });
  });
}
