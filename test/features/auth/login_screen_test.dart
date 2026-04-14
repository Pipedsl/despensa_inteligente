import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen renderiza campos y botones principales',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar con Google'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Entrar como test'), findsOneWidget);
  });
}
