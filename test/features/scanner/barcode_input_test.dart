// test/features/scanner/barcode_input_test.dart
import 'package:despensa_inteligente/features/scanner/presentation/barcode_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('modo teclado dispara onBarcode al tocar Usar', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarcodeInput(
            initialTab: BarcodeInputTab.keyboard,
            onBarcode: (bc) => captured = bc,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '7802800000000');
    await tester.tap(find.text('Usar'));
    await tester.pumpAndSettle();
    expect(captured, '7802800000000');
  });

  testWidgets('barcode vacío no dispara callback', (tester) async {
    String? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarcodeInput(
            initialTab: BarcodeInputTab.keyboard,
            onBarcode: (bc) => captured = bc,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Usar'));
    await tester.pumpAndSettle();
    expect(captured, isNull);
  });
}
