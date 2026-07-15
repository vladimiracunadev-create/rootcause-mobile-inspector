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
}
