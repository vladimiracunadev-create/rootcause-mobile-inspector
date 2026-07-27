import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/main.dart';

void main() {
  testWidgets('la app arranca y degrada con elegancia sin canal nativo', (
    tester,
  ) async {
    // En el entorno de test no hay MethodChannel nativo: el puente debe
    // degradar a un snapshot neutro sin crashear (MissingPluginException
    // capturada en PlatformCollectors).
    await tester.pumpWidget(const RootCauseApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('RootCause'), findsOneWidget);
    // Con snapshot neutro el veredicto existe y las 10 pestañas están.
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(10));
  });

  testWidgets('autodetecta el idioma del equipo y el menú permite cambiarlo', (
    tester,
  ) async {
    await tester.pumpWidget(const RootCauseApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Idioma automático: el entorno de test corre en en_US, así que arranca
    // en inglés (no en español).
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Resumen'), findsNothing);

    // El menú de idioma permite forzar español. Se usan pumps acotados en
    // vez de pumpAndSettle: el checkmark del menú anima de forma continua y
    // haría que pumpAndSettle nunca "asiente".
    await tester.tap(find.byIcon(Icons.translate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // El texto del ítem va alineado a la derecha; se pulsa el ítem completo.
    await tester.tap(
      find
          .ancestor(
            of: find.text('Español').last,
            matching: find.byType(InkWell),
          )
          .first,
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Summary'), findsNothing);
  });
}
