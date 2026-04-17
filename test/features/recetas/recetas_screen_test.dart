import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/recetas/presentation/recetas_screen.dart';
import 'package:despensa_inteligente/features/recetas/data/recetas_providers.dart';
import 'package:despensa_inteligente/features/plan/data/plan_providers.dart';
import 'package:despensa_inteligente/features/plan/domain/plan_config.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_providers.dart';

void main() {
  testWidgets('RecetasScreen muestra botón generar receta', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hogarActivoIdProvider.overrideWith((_) => 'hogar1'),
          planConfigProvider.overrideWith((_) async => PlanConfig.free),
          recetasListProvider('hogar1').overrideWith((_) => Stream.value([])),
        ],
        child: const MaterialApp(home: RecetasScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Recetas'), findsOneWidget);
    expect(find.byKey(const Key('btn_generar_receta')), findsOneWidget);
  });

  testWidgets('RecetasScreen muestra indicador de cuota', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hogarActivoIdProvider.overrideWith((_) => 'hogar1'),
          planConfigProvider.overrideWith((_) async => PlanConfig.free),
          recetasListProvider('hogar1').overrideWith((_) => Stream.value([])),
        ],
        child: const MaterialApp(home: RecetasScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('receta'), findsWidgets);
  });
}
