// lib/features/productos_globales/data/productos_globales_repository.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';

abstract class CallableFn {
  Future<Map<String, dynamic>> call(Map<String, dynamic> args);
}

class _FirebaseCallable implements CallableFn {
  final HttpsCallable _fn;
  _FirebaseCallable(this._fn);
  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final res = await _fn.call(args);
    return Map<String, dynamic>.from(res.data as Map);
  }
}

class ProductosGlobalesRepository {
  final CallableFn lookupFn;
  final CallableFn proponerFn;

  ProductosGlobalesRepository({
    required this.lookupFn,
    required this.proponerFn,
  });

  factory ProductosGlobalesRepository.firebase() {
    final fns = FirebaseFunctions.instanceFor(region: 'us-central1');
    return ProductosGlobalesRepository(
      lookupFn: _FirebaseCallable(fns.httpsCallable('lookupProductoGlobal')),
      proponerFn:
          _FirebaseCallable(fns.httpsCallable('proponerProductoGlobal')),
    );
  }

  Future<LookupResult> lookupByBarcode(String barcode) async {
    final data = await lookupFn.call({'barcode': barcode});
    return LookupResult.fromMap(data);
  }

  Future<LookupResult> proponer({
    required String barcode,
    required String nombre,
    String? marca,
    List<String>? categorias,
    String? imagenUrl,
    Nutricional? nutricional,
  }) async {
    final draft = <String, dynamic>{
      'barcode': barcode,
      'nombre': nombre,
      if (marca != null) 'marca': marca,
      if (categorias != null) 'categorias': categorias,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
      if (nutricional != null && nutricional.toMap().isNotEmpty)
        'nutricional': nutricional.toMap(),
    };
    final data = await proponerFn.call({'draft': draft});
    return LookupResult.fromMap(data);
  }
}
