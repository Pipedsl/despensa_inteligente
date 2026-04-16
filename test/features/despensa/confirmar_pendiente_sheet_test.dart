// test/features/despensa/confirmar_pendiente_sheet_test.dart
import 'package:despensa_inteligente/features/despensa/presentation/confirmar_pendiente_sheet.dart';
import 'package:despensa_inteligente/features/productos_globales/domain/producto_global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra sugerencia y confirma con datos editados', (tester) async {
    SugerenciaNormalizador? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => FilledButton(
              onPressed: () async {
                final res = await showConfirmarPendienteSheet(
                  ctx,
                  sugerencia: const SugerenciaNormalizador(
                    nombre: 'Leche Soprole 1 L',
                    marca: 'Soprole',
                    categorias: ['lacteos'],
                    confianza: 0.6,
                    correcciones: ['capitalización'],
                  ),
                );
                confirmed = res;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Leche Soprole 1 L'), findsOneWidget);
    expect(find.text('capitalización'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(confirmed, isNotNull);
    expect(confirmed!.nombre, 'Leche Soprole 1 L');
  });
}
