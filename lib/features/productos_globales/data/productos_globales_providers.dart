// lib/features/productos_globales/data/productos_globales_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'productos_globales_repository.dart';

final productosGlobalesRepositoryProvider =
    Provider<ProductosGlobalesRepository>(
  (ref) => ProductosGlobalesRepository.firebase(),
);
