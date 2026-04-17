import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/recetas/presentation/detalle_receta_screen.dart';
import 'package:despensa_inteligente/features/recetas/domain/receta.dart';
import 'package:despensa_inteligente/features/hogares/data/hogar_providers.dart';

final _fakeReceta = Receta(
  id: 'rec1',
  generadaPor: 'uid1',
  fecha: DateTime(2026, 4, 16),
  ingredientesUsados: ['Leche', 'Huevos'],
  contenido: const RecetaContenido(
    titulo: 'Tortilla de Papas',
    pasos: ['Pelar papas.', 'Freír con aceite.'],
    tiempo: '20 minutos',
    porciones: 2,
  ),
  modeloIa: 'gemini-2.0-flash',
  tokensUsados: 400,
  fromCache: false,
  hashIngredientes: 'abc',
);

void main() {
  testWidgets('DetalleRecetaScreen muestra título y pasos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hogarActivoIdProvider.overrideWith((_) => 'hogar1'),
        ],
        child: MaterialApp(
          home: DetalleRecetaScreen(receta: _fakeReceta),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Tortilla de Papas'), findsOneWidget);
    expect(find.text('Pelar papas.'), findsOneWidget);
    expect(find.text('Freír con aceite.'), findsOneWidget);
    expect(find.text('20 minutos'), findsOneWidget);
  });
}
