import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';

abstract interface class GenerarRecetaCallable {
  Future<Map<String, dynamic>> call(Map<String, dynamic> data);
}

class _FirebaseGenerarCallable implements GenerarRecetaCallable {
  final HttpsCallable _fn;
  _FirebaseGenerarCallable(this._fn);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    final result = await _fn.call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }
}

sealed class GenerarRecetaResult {}

class GenerarOk extends GenerarRecetaResult {
  final RecetaContenido receta;
  final String recetaId;
  final bool fromCache;
  final int recetasRestantes;
  GenerarOk({
    required this.receta,
    required this.recetaId,
    required this.fromCache,
    required this.recetasRestantes,
  });
}

class GenerarLimitExceeded extends GenerarRecetaResult {
  final int recetasUsadas;
  final int maxRecetasMes;
  GenerarLimitExceeded({required this.recetasUsadas, required this.maxRecetasMes});
}

class GenerarDespensaVacia extends GenerarRecetaResult {}

class RecetasRepository {
  final GenerarRecetaCallable generarFn;
  final FirebaseFirestore? _firestore;

  RecetasRepository({required this.generarFn, FirebaseFirestore? firestore})
      : _firestore = firestore;

  factory RecetasRepository.firebase() {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    return RecetasRepository(
      generarFn: _FirebaseGenerarCallable(
          functions.httpsCallable('generarReceta')),
      firestore: FirebaseFirestore.instance,
    );
  }

  Future<GenerarRecetaResult> generarReceta({
    required String hogarId,
    required String? preferencias,
  }) async {
    final data = <String, dynamic>{'hogarId': hogarId};
    if (preferencias != null && preferencias.isNotEmpty) {
      data['preferencias'] = preferencias;
    }
    final response = await generarFn.call(data);
    final status = response['status'] as String;

    switch (status) {
      case 'ok':
        return GenerarOk(
          receta: RecetaContenido.fromMap(
              response['receta'] as Map<String, dynamic>),
          recetaId: response['recetaId'] as String,
          fromCache: response['fromCache'] as bool? ?? false,
          recetasRestantes: (response['recetasRestantes'] as num?)?.toInt() ?? 0,
        );
      case 'plan_limit_exceeded':
        return GenerarLimitExceeded(
          recetasUsadas: (response['recetasUsadas'] as num?)?.toInt() ?? 0,
          maxRecetasMes: (response['maxRecetasMes'] as num?)?.toInt() ?? 0,
        );
      case 'despensa_vacia':
      default:
        return GenerarDespensaVacia();
    }
  }

  Stream<List<Receta>> listarRecetas(String hogarId, {int? limite}) {
    Query<Map<String, dynamic>> q =
        (_firestore ?? FirebaseFirestore.instance)
            .collection('hogares/$hogarId/recetas')
            .orderBy('fecha', descending: true);
    if (limite != null && limite > 0) q = q.limit(limite);
    return q.snapshots().map(
        (snap) => snap.docs.map((d) => Receta.fromMap(d.data(), d.id)).toList());
  }
}
