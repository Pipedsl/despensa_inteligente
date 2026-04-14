import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/home/presentation/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen muestra título y botón cerrar sesión',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump(); // Permite que el stream emita

    expect(find.text('DespensaInteligente'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
