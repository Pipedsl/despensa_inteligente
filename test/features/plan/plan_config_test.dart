import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/plan/domain/plan_config.dart';

void main() {
  group('PlanConfig', () {
    test('fromMap crea instancia free correctamente', () {
      final map = {
        'id': 'free',
        'maxRecetasMes': 3,
        'modeloReceta': 'gemini-2.0-flash',
        'maxHogares': 1,
        'maxMiembrosHogar': 4,
        'maxProductos': 30,
        'historialLimite': 10,
        'stripePriceId': null,
      };
      final plan = PlanConfig.fromMap(map, 'free');
      expect(plan.id, 'free');
      expect(plan.maxRecetasMes, 3);
      expect(plan.modeloReceta, 'gemini-2.0-flash');
      expect(plan.esIlimitadoMiembros, isFalse);
      expect(plan.historialCompleto, isFalse);
    });

    test('fromMap pro con -1 marca ilimitado', () {
      final map = {
        'id': 'pro',
        'maxRecetasMes': 50,
        'modeloReceta': 'gemini-2.5-flash',
        'maxHogares': 3,
        'maxMiembrosHogar': -1,
        'maxProductos': 300,
        'historialLimite': -1,
        'stripePriceId': null,
      };
      final plan = PlanConfig.fromMap(map, 'pro');
      expect(plan.esIlimitadoMiembros, isTrue);
      expect(plan.historialCompleto, isTrue);
    });
  });
}
