import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/config_store.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';
import 'package:rootcause_mobile_inspector/platform/capture_service.dart';
import 'package:rootcause_mobile_inspector/platform/collectors.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rootcause-capture-test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  // Sin canal nativo (tests) el colector degrada a snapshot neutro, cuyo
  // 0 % de memoria/disco produce veredicto CRÍTICO: útil justo para
  // probar la transición.
  const service = CaptureService(PlatformCollectors());

  test(
    'la PRIMERA captura crítica marca la transición (wentCritical)',
    () async {
      final outcome = await service.capture(
        config: const AppConfig(),
        directoryPath: tmp.path,
      );
      expect(outcome.verdict.severity, Severity.critical);
      expect(outcome.wentCritical, isTrue);
    },
  );

  test('crítico sostenido NO repite la alerta (solo transición)', () async {
    await service.capture(config: const AppConfig(), directoryPath: tmp.path);
    final second = await service.capture(
      config: const AppConfig(),
      directoryPath: tmp.path,
    );
    expect(second.verdict.severity, Severity.critical);
    expect(second.wentCritical, isFalse);
    expect(second.history, hasLength(2));
  });

  test('el motor genera new-apps con severidad y evidencia', () {
    const engine = RuleEngine();
    final verdict = engine.evaluate(
      buildSnapshot(),
      newApps: [
        buildAppRisk(packageName: 'com.n1', label: 'Uno', sideloaded: true),
        buildAppRisk(packageName: 'com.n2', label: 'Dos'),
      ],
    );
    final finding = verdict.findings.singleWhere((f) => f.id == 'new-apps');
    expect(finding.severity, Severity.warning);
    expect(finding.args[0], '2');
    expect(finding.args[1], contains('Uno'));
    expect(finding.args[2], '1'); // una de ellas con sideload
  });

  test('sin apps nuevas no hay hallazgo new-apps', () {
    const engine = RuleEngine();
    final verdict = engine.evaluate(buildSnapshot());
    expect(verdict.findings.where((f) => f.id == 'new-apps'), isEmpty);
  });
}
