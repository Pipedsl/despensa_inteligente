import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:despensa_inteligente/features/recetas/presentation/upgrade_screen.dart';
import 'package:despensa_inteligente/features/plan/data/plan_providers.dart';
import 'package:despensa_inteligente/features/plan/data/flow_repository.dart';

class FakeFlowCallable implements FlowCallable {
  final FlowResult result;
  int callCount = 0;
  FakeFlowCallable(this.result);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    callCount++;
    if (result is FlowUrlOk) {
      final ok = result as FlowUrlOk;
      return {'url': ok.url, 'token': ok.token};
    }
    throw Exception((result as FlowError).message);
  }
}

class _SlowFakeFlowCallable implements FlowCallable {
  final FlowResult result;
  _SlowFakeFlowCallable(this.result);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (result is FlowUrlOk) {
      final ok = result as FlowUrlOk;
      return {'url': ok.url, 'token': ok.token};
    }
    throw Exception((result as FlowError).message);
  }
}

void main() {
  testWidgets('UpgradeScreen muestra título Plan Pro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowRepositoryProvider.overrideWith((_) => FlowRepository(
            crearSuscripcionFn: FakeFlowCallable(
              FlowUrlOk(url: 'https://flow.cl/register/test', token: 'tok'),
            ),
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
          flowRepositoryProvider.overrideWith((_) => FlowRepository(
            crearSuscripcionFn: FakeFlowCallable(
              FlowUrlOk(url: 'https://flow.cl/register/test', token: 'tok'),
            ),
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
          flowRepositoryProvider.overrideWith((_) => FlowRepository(
            crearSuscripcionFn: FakeFlowCallable(
              FlowUrlOk(url: 'https://flow.cl/register/test', token: 'tok'),
            ),
          )),
        ],
        child: const MaterialApp(home: UpgradeScreen()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('btn_upgrade_pro')), findsOneWidget);
  });

  testWidgets('UpgradeScreen muestra error snackbar si Flow falla', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flowRepositoryProvider.overrideWith((_) => FlowRepository(
            crearSuscripcionFn: FakeFlowCallable(FlowError('Error de prueba')),
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
          flowRepositoryProvider.overrideWith((_) => FlowRepository(
            crearSuscripcionFn: _SlowFakeFlowCallable(FlowError('fail')),
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
