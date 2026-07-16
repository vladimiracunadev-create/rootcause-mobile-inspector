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
    // Con snapshot neutro el veredicto existe y las 7 pestañas están.
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('arranca en español por defecto y el botón cambia a inglés', (
    tester,
  ) async {
    await tester.pumpWidget(const RootCauseApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Español por defecto aunque el entorno de test corre con locale en_US.
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Summary'), findsNothing);

    await tester.tap(find.byIcon(Icons.translate));
    await tester.pump();

    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Resumen'), findsNothing);
  });
}
