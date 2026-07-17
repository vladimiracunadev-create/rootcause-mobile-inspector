import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/baseline_store.dart';

import 'helpers.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rootcause-baseline-test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('la primera captura inicializa el baseline EN SILENCIO', () async {
    final store = BaselineStore(tmp.path);
    final newApps = await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.a'), buildAppRisk(packageName: 'com.b')],
      nowMillis: 1000,
      auditSupported: true,
    );
    expect(newApps, isEmpty, reason: 'lo ya instalado no es "nuevo"');
  });

  test('una app instalada después aparece como nueva UNA vez', () async {
    final store = BaselineStore(tmp.path);
    await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.a')],
      nowMillis: 1000,
      auditSupported: true,
    );

    final second = await store.diffAndUpdate(
      [
        buildAppRisk(packageName: 'com.a'),
        buildAppRisk(packageName: 'com.nueva', label: 'Nueva'),
      ],
      nowMillis: 2000,
      auditSupported: true,
    );
    expect(second.map((a) => a.packageName), ['com.nueva']);

    // La siguiente captura ya la absorbió el baseline.
    final third = await store.diffAndUpdate(
      [
        buildAppRisk(packageName: 'com.a'),
        buildAppRisk(packageName: 'com.nueva'),
      ],
      nowMillis: 3000,
      auditSupported: true,
    );
    expect(third, isEmpty);
  });

  test('desinstalar y reinstalar vuelve a contar como evento', () async {
    final store = BaselineStore(tmp.path);
    await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.x')],
      nowMillis: 1000,
      auditSupported: true,
    );
    // Desinstalada: se poda del baseline.
    await store.diffAndUpdate(const [], nowMillis: 2000, auditSupported: true);
    // Reinstalada: nueva otra vez.
    final again = await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.x')],
      nowMillis: 3000,
      auditSupported: true,
    );
    expect(again, hasLength(1));
  });

  test('en iOS (sin auditoría) no se crea baseline ni se acusa', () async {
    final store = BaselineStore(tmp.path);
    final result = await store.diffAndUpdate(
      const [],
      nowMillis: 1000,
      auditSupported: false,
    );
    expect(result, isEmpty);
    expect(
      File('${tmp.path}/rootcause-apps-baseline.json').existsSync(),
      isFalse,
    );
  });

  test('baseline corrupto se reconstruye sin acusar a nadie', () async {
    await File(
      '${tmp.path}/rootcause-apps-baseline.json',
    ).writeAsString('{roto');
    final store = BaselineStore(tmp.path);
    final result = await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.a')],
      nowMillis: 1000,
      auditSupported: true,
    );
    expect(result, isEmpty, reason: 'reconstrucción = primera vez silenciosa');
  });
}
