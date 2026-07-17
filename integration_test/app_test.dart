// Test de integración end-to-end — se ejecuta en un emulador o teléfono:
//   flutter test integration_test
//
// A diferencia de los tests de widget (test/), aquí SÍ hay canal nativo,
// así que ejercita el flujo real: arranque → primera captura → pestañas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rootcause_mobile_inspector/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arranca, captura y muestra las 9 pestañas', (tester) async {
    await tester.pumpWidget(const RootCauseApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Si aparece el onboarding (primera vez), completarlo.
    final start = find.text('Empezar');
    if (start.evaluate().isNotEmpty) {
      final next = find.text('Siguiente');
      while (next.evaluate().isNotEmpty) {
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(9));
    // La captura real produjo un veredicto en el semáforo.
    expect(find.byType(VerdictBanner), findsOneWidget);
  });
}
