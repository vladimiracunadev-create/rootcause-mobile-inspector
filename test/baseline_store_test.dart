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
    final diff = await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.a'), buildAppRisk(packageName: 'com.b')],
      nowMillis: 1000,
      auditSupported: true,
    );
    expect(diff.isEmpty, isTrue, reason: 'lo ya instalado no es "nuevo"');
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
    expect(second.newApps.map((a) => a.packageName), ['com.nueva']);

    // La siguiente captura ya la absorbió el baseline.
    final third = await store.diffAndUpdate(
      [
        buildAppRisk(packageName: 'com.a'),
        buildAppRisk(packageName: 'com.nueva'),
      ],
      nowMillis: 3000,
      auditSupported: true,
    );
    expect(third.isEmpty, isTrue);
  });

  test('cambio de versión → ACTUALIZADA; ausencia → ELIMINADA', () async {
    final store = BaselineStore(tmp.path);
    await store.diffAndUpdate(
      [
        buildAppRisk(packageName: 'com.a', versionName: '1.0'),
        buildAppRisk(packageName: 'com.b', versionName: '2.0'),
      ],
      nowMillis: 1000,
      auditSupported: true,
    );
    final diff = await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.a', versionName: '1.1')],
      nowMillis: 2000,
      auditSupported: true,
    );
    expect(diff.updatedApps.map((a) => a.packageName), ['com.a']);
    expect(diff.removedPackages, ['com.b']);
    expect(diff.newApps, isEmpty);
  });

  test('baseline v0.3/v0.4 (solo firstSeen) migra sin acusar', () async {
    await File('${tmp.path}/rootcause-apps-baseline.json').writeAsString(
      '{"packages":{"com.a":1000}}', // formato antiguo: int directo
    );
    final store = BaselineStore(tmp.path);
    final diff = await store.diffAndUpdate(
      [buildAppRisk(packageName: 'com.a', versionName: '3.0')],
      nowMillis: 2000,
      auditSupported: true,
    );
    expect(diff.isEmpty, isTrue, reason: 'sin versión previa no hay acusación');
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
    expect(again.newApps, hasLength(1));
  });

  test('en iOS (sin auditoría) no se crea baseline ni se acusa', () async {
    final store = BaselineStore(tmp.path);
    final result = await store.diffAndUpdate(
      const [],
      nowMillis: 1000,
      auditSupported: false,
    );
    expect(result.isEmpty, isTrue);
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
    expect(
      result.isEmpty,
      isTrue,
      reason: 'reconstrucción = primera vez silenciosa',
    );
  });
}
