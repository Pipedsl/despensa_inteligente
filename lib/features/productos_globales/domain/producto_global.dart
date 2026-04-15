// lib/features/productos_globales/domain/producto_global.dart
class Nutricional {
  final double? energiaKcal;
  final double? proteinasG;
  final double? grasasG;
  final double? carbosG;
  final double? sodioMg;

  const Nutricional({
    this.energiaKcal,
    this.proteinasG,
    this.grasasG,
    this.carbosG,
    this.sodioMg,
  });

  factory Nutricional.fromMap(Map<String, dynamic> m) => Nutricional(
        energiaKcal: (m['energiaKcal'] as num?)?.toDouble(),
        proteinasG: (m['proteinasG'] as num?)?.toDouble(),
        grasasG: (m['grasasG'] as num?)?.toDouble(),
        carbosG: (m['carbosG'] as num?)?.toDouble(),
        sodioMg: (m['sodioMg'] as num?)?.toDouble(),
      );
}

class ProductoGlobal {
  final String barcode;
  final String nombre;
  final String? marca;
  final List<String> categorias;
  final String? imagenUrl;
  final Nutricional? nutricional;
  final List<String> contribuidores;
  final List<String> camposFaltantes;
  final String estado; // publicado | pendiente_revision
  final String source;

  const ProductoGlobal({
    required this.barcode,
    required this.nombre,
    required this.marca,
    required this.categorias,
    required this.imagenUrl,
    required this.nutricional,
    required this.contribuidores,
    required this.camposFaltantes,
    required this.estado,
    required this.source,
  });

  factory ProductoGlobal.fromMap(Map<String, dynamic> m) => ProductoGlobal(
        barcode: m['barcode'] as String,
        nombre: m['nombre'] as String,
        marca: m['marca'] as String?,
        categorias: (m['categorias'] as List? ?? const [])
            .map((e) => e as String)
            .toList(),
        imagenUrl: m['imagenUrl'] as String?,
        nutricional: m['nutricional'] == null
            ? null
            : Nutricional.fromMap(
                Map<String, dynamic>.from(m['nutricional'] as Map),
              ),
        contribuidores: (m['contribuidores'] as List? ?? const [])
            .map((e) => e as String)
            .toList(),
        camposFaltantes: (m['camposFaltantes'] as List? ?? const [])
            .map((e) => e as String)
            .toList(),
        estado: m['estado'] as String,
        source: m['source'] as String,
      );
}

class SugerenciaNormalizador {
  final String nombre;
  final String? marca;
  final List<String> categorias;
  final double confianza;
  final List<String> correcciones;

  const SugerenciaNormalizador({
    required this.nombre,
    required this.marca,
    required this.categorias,
    required this.confianza,
    required this.correcciones,
  });

  factory SugerenciaNormalizador.fromMap(Map<String, dynamic> m) =>
      SugerenciaNormalizador(
        nombre: m['nombre'] as String,
        marca: m['marca'] as String?,
        categorias: (m['categorias'] as List).map((e) => e as String).toList(),
        confianza: (m['confianza'] as num).toDouble(),
        correcciones:
            (m['correcciones'] as List).map((e) => e as String).toList(),
      );
}

sealed class LookupResult {
  const LookupResult();
  factory LookupResult.fromMap(Map<String, dynamic> m) {
    switch (m['status'] as String) {
      case 'found':
        return LookupFound(
          ProductoGlobal.fromMap(
            Map<String, dynamic>.from(m['producto'] as Map),
          ),
        );
      case 'pending_review':
        return LookupPendingReview(
          draftId: m['draftId'] as String,
          sugerencia: SugerenciaNormalizador.fromMap(
            Map<String, dynamic>.from(m['sugerencia'] as Map),
          ),
        );
      case 'not_found':
      default:
        return const LookupNotFound();
    }
  }
}

class LookupFound extends LookupResult {
  final ProductoGlobal producto;
  const LookupFound(this.producto);
}

class LookupPendingReview extends LookupResult {
  final String draftId;
  final SugerenciaNormalizador sugerencia;
  const LookupPendingReview({required this.draftId, required this.sugerencia});
}

class LookupNotFound extends LookupResult {
  const LookupNotFound();
}
