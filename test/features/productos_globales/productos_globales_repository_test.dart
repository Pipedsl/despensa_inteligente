// test/features/productos_globales/productos_globales_repository_test.dart
import 'package:despensa_inteligente/features/productos_globales/data/productos_globales_repository.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCallable implements CallableFn {
  final Map<String, dynamic> Function(Map<String, dynamic>) respond;
  Map<String, dynamic>? lastArgs;
  FakeCallable(this.respond);
  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    lastArgs = args;
    return respond(args);
  }
}

void main() {
  test('lookupByBarcode parsea respuesta found', () async {
    final callable = FakeCallable((_) => {
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
    final repo = ProductosGlobalesRepository(
      lookupFn: callable,
      proponerFn: FakeCallable((_) => {'status': 'not_found'}),
    );
    final res = await repo.lookupByBarcode('1');
    expect(res, isA<LookupFound>());
    expect(callable.lastArgs, {'barcode': '1'});
  });

  test('proponer envía draft', () async {
    final proponer = FakeCallable((_) => {
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
    final repo = ProductosGlobalesRepository(
      lookupFn: FakeCallable((_) => {'status': 'not_found'}),
      proponerFn: proponer,
    );
    final res = await repo.proponer(
      barcode: '1',
      nombre: 'leche soprole',
      marca: 'soprole',
    );
    expect(res, isA<LookupFound>());
    expect(proponer.lastArgs!['draft'], {
      'barcode': '1',
      'nombre': 'leche soprole',
      'marca': 'soprole',
    });
  });
}
