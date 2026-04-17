import 'package:cloud_firestore/cloud_firestore.dart';

class RecetaContenido {
  final String titulo;
  final List<String> pasos;
  final String tiempo;
  final int porciones;

  const RecetaContenido({
    required this.titulo,
    required this.pasos,
    required this.tiempo,
    required this.porciones,
  });

  factory RecetaContenido.fromMap(Map<String, dynamic> map) {
    return RecetaContenido(
      titulo: map['titulo'] as String? ?? '',
      pasos: (map['pasos'] as List<dynamic>? ?? []).cast<String>(),
      tiempo: map['tiempo'] as String? ?? '',
      porciones: (map['porciones'] as num?)?.toInt() ?? 0,
    );
  }
}

class Receta {
  final String id;
  final String generadaPor;
  final DateTime fecha;
  final List<String> ingredientesUsados;
  final RecetaContenido contenido;
  final String modeloIa;
  final int tokensUsados;
  final bool fromCache;
  final String hashIngredientes;

  const Receta({
    required this.id,
    required this.generadaPor,
    required this.fecha,
    required this.ingredientesUsados,
    required this.contenido,
    required this.modeloIa,
    required this.tokensUsados,
    required this.fromCache,
    required this.hashIngredientes,
  });

  factory Receta.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic v) {
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    final ingredientes = (map['ingredientesUsados'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['nombre'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    return Receta(
      id: id,
      generadaPor: map['generadaPor'] as String? ?? '',
      fecha: parseDate(map['fecha']),
      ingredientesUsados: ingredientes,
      contenido: RecetaContenido.fromMap(
          map['contenido'] as Map<String, dynamic>? ?? {}),
      modeloIa: map['modeloIa'] as String? ?? 'gemini-2.0-flash',
      tokensUsados: (map['tokensUsados'] as num?)?.toInt() ?? 0,
      fromCache: map['fromCache'] as bool? ?? false,
      hashIngredientes: map['hashIngredientes'] as String? ?? '',
    );
  }
}
