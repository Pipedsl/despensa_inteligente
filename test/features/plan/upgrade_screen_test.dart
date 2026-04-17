import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/recetas/presentation/upgrade_screen.dart';
import 'package:despensa_inteligente/features/plan/data/plan_providers.dart';
import 'package:despensa_inteligente/features/plan/data/stripe_repository.dart';
import 'package:despensa_inteligente/features/plan/domain/plan_config.dart';

class FakeCheckoutCallable implements CheckoutCallable {
  final CheckoutResult result;
  int callCount = 0;
  FakeCheckoutCallable(this.result);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    callCount++;
    if (result is CheckoutUrlOk) {
      return {'url': (result as CheckoutUrlOk).url};
    }
    throw Exception((result as CheckoutError).message);
  }
}

class _SlowFakeCheckoutCallable implements CheckoutCallable {
  final CheckoutResult result;
  _SlowFakeCheckoutCallable(this.result);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (result is CheckoutUrlOk) {
      return {'url': (result as CheckoutUrlOk).url};
    }
    throw Exception((result as CheckoutError).message);
  }
}

const _proConfig = PlanConfig(
  id: 'pro',
  maxRecetasMes: 50,
  modeloReceta: 'gemini-2.5-flash',
  maxHogares: 3,
  maxMiembrosHogar: -1,
  maxProductos: 300,
  historialLimite: -1,
  stripePriceId: 'price_test_pro',
);

void main() {
  testWidgets('UpgradeScreen muestra título Plan Pro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planConfigProvider.overrideWith((_) async => _proConfig),
          stripeRepositoryProvider.overrideWith((_) => StripeRepository(
            checkoutFn: FakeCheckoutCallable(CheckoutUrlOk('https://stripe.com/pay/test')),
          )),
        ],
        child: const MaterialApp(home: UpgradeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Desbloquea el Plan Pro'), findsOneWidget);
  });

  testWidgets('UpgradeScreen muestra beneficios con 50 recetas', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planConfigProvider.overrideWith((_) async => _proConfig),
          stripeRepositoryProvider.overrideWith((_) => StripeRepository(
            checkoutFn: FakeCheckoutCallable(CheckoutUrlOk('https://stripe.com/pay/test')),
          )),
        ],
        child: const MaterialApp(home: UpgradeScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('50 recetas'), findsOneWidget);
  });

  testWidgets('UpgradeScreen tiene botón btn_upgrade_pro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planConfigProvider.overrideWith((_) async => _proConfig),
          stripeRepositoryProvider.overrideWith((_) => StripeRepository(
            checkoutFn: FakeCheckoutCallable(CheckoutUrlOk('https://stripe.com/pay/test')),
          )),
        ],
        child: const MaterialApp(home: UpgradeScreen()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('btn_upgrade_pro')), findsOneWidget);
  });

  testWidgets('UpgradeScreen muestra error snackbar si checkout falla', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planConfigProvider.overrideWith((_) async => _proConfig),
          stripeRepositoryProvider.overrideWith((_) => StripeRepository(
            checkoutFn: FakeCheckoutCallable(CheckoutError('Error de prueba')),
          )),
        ],
        child: const MaterialApp(home: UpgradeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('btn_upgrade_pro')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_upgrade_pro')));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Error'), findsWidgets);
  });

  testWidgets('UpgradeScreen muestra CircularProgressIndicator mientras carga', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          planConfigProvider.overrideWith((_) async => _proConfig),
          stripeRepositoryProvider.overrideWith((_) => StripeRepository(
            checkoutFn: _SlowFakeCheckoutCallable(CheckoutError('fail')),
          )),
        ],
        child: const MaterialApp(home: UpgradeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('btn_upgrade_pro')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_upgrade_pro')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
