import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/recetas/data/recetas_repository.dart';

class FakeGenerarCallable implements GenerarRecetaCallable {
  final Map<String, dynamic>? response;
  final Exception? error;
  int callCount = 0;

  FakeGenerarCallable({this.response, this.error});

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    callCount++;
    if (error != null) throw error!;
    return response ?? {};
  }
}

void main() {
  group('RecetasRepository.generarReceta', () {
    test('retorna receta cuando status es ok', () async {
      final fake = FakeGenerarCallable(response: {
        'status': 'ok',
        'receta': {
          'titulo': 'Tortilla',
          'pasos': ['Paso 1'],
          'tiempo': '10 min',
          'porciones': 2,
        },
        'recetaId': 'rec1',
        'fromCache': false,
        'recetasRestantes': 2,
      });
      final repo = RecetasRepository(generarFn: fake);
      final result = await repo.generarReceta(hogarId: 'hogar1', preferencias: null);
      expect(result, isA<GenerarOk>());
      final ok = result as GenerarOk;
      expect(ok.receta.titulo, 'Tortilla');
      expect(ok.recetasRestantes, 2);
    });

    test('retorna GenerarLimitExceeded cuando status es plan_limit_exceeded', () async {
      final fake = FakeGenerarCallable(response: {
        'status': 'plan_limit_exceeded',
        'recetasUsadas': 3,
        'maxRecetasMes': 3,
      });
      final repo = RecetasRepository(generarFn: fake);
      final result = await repo.generarReceta(hogarId: 'hogar1', preferencias: null);
      expect(result, isA<GenerarLimitExceeded>());
    });

    test('retorna GenerarDespensaVacia cuando status es despensa_vacia', () async {
      final fake = FakeGenerarCallable(response: {'status': 'despensa_vacia'});
      final repo = RecetasRepository(generarFn: fake);
      final result = await repo.generarReceta(hogarId: 'hogar1', preferencias: null);
      expect(result, isA<GenerarDespensaVacia>());
    });
  });
}
