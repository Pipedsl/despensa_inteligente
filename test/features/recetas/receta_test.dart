import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';

void main() {
  group('Receta', () {
    test('fromMap crea instancia correctamente', () {
      final map = {
        'generadaPor': 'uid1',
        'fecha': DateTime(2026, 4, 16).millisecondsSinceEpoch,
        'ingredientesUsados': [
          {'nombre': 'Leche'},
          {'nombre': 'Huevos'},
        ],
        'contenido': {
          'titulo': 'Tortilla',
          'pasos': ['Paso 1', 'Paso 2'],
          'tiempo': '20 minutos',
          'porciones': 2,
        },
        'modeloIa': 'gemini-2.0-flash',
        'tokensUsados': 500,
        'fromCache': false,
        'hashIngredientes': 'abc123',
      };
      final receta = Receta.fromMap(map, 'receta1');
      expect(receta.id, 'receta1');
      expect(receta.contenido.titulo, 'Tortilla');
      expect(receta.ingredientesUsados.length, 2);
      expect(receta.fromCache, isFalse);
    });
  });
}
