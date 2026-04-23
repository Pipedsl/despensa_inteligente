// lib/features/productos_globales/data/productos_globales_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'productos_globales_repository.dart';

final productosGlobalesRepositoryProvider =
    Provider<ProductosGlobalesRepository>(
  (ref) => ProductosGlobalesRepository.firebase(),
);

final productoLookupProvider =
    FutureProvider.family<LookupResult, String>((ref, barcode) {
  return ref.read(productosGlobalesRepositoryProvider).lookupByBarcode(barcode);
});
