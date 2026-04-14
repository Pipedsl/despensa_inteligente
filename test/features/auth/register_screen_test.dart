import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/auth/presentation/register_screen.dart';

void main() {
  testWidgets('RegisterScreen muestra campos de nombre, email, contraseña y botón',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });
}
