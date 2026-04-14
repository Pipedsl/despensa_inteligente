import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:despensa_inteligente/features/hogares/presentation/onboarding_hogar_screen.dart';

void main() {
  testWidgets('OnboardingHogarScreen muestra campo de nombre y botón',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OnboardingHogarScreen()),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Crear mi hogar'), findsOneWidget);
  });
}
