import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';

import 'helpers.dart';

void main() {
  const engine = RuleEngine();

  // buildSnapshot fija el "ahora" en 1700000000000 = 2023-11-14.
  Snapshot withPatch(String patch) => buildSnapshot(
    device: DeviceInfo(
      manufacturer: 'Test',
      model: 'Unit',
      osVersion: '14',
      sdkInt: 34,
      securityPatch: patch,
      cpuCores: 8,
      uptimeMillis: 3600000,
      rootIndicators: const [],
      appsAuditSupported: true,
    ),
  );

  group('RuleEngine — patch-old (parche de seguridad antiguo)', () {
    test('parche reciente (< 180 días) no genera hallazgo', () {
      final verdict = engine.evaluate(withPatch('2023-10-01'));
      expect(verdict.findings.where((f) => f.id == 'patch-old'), isEmpty);
    });

    test('parche de más de 180 días → WARNING con la edad como evidencia', () {
      final verdict = engine.evaluate(withPatch('2023-04-01'));
      final finding = verdict.findings.singleWhere((f) => f.id == 'patch-old');
      expect(finding.severity, Severity.warning);
      expect(int.parse(finding.args[0]), greaterThanOrEqualTo(180));
      expect(finding.args[1], '2023-04-01');
    });

    test('parche de más de 365 días → CRITICAL', () {
      final verdict = engine.evaluate(withPatch('2022-06-01'));
      final finding = verdict.findings.singleWhere((f) => f.id == 'patch-old');
      expect(finding.severity, Severity.critical);
    });

    test('fecha no parseable (iOS reporta versión, no fecha) → omitida', () {
      final verdict = engine.evaluate(withPatch('iOS 17.2'));
      expect(verdict.findings.where((f) => f.id == 'patch-old'), isEmpty);
    });
  });

  group('Uso por app (acceso de uso opt-in)', () {
    test('foregroundMillis24h presente se parsea; ausente degrada a -1', () {
      final withUsage = AppRisk.fromMap(const {
        'packageName': 'com.a',
        'label': 'A',
        'foregroundMillis24h': 5400000,
      });
      expect(withUsage.foregroundMillis24h, 5400000);

      final without = AppRisk.fromMap(const {
        'packageName': 'com.b',
        'label': 'B',
      });
      expect(without.foregroundMillis24h, -1);
    });

    test('usageAccessGranted ausente degrada a false', () {
      expect(DeviceInfo.fromMap(const {}).usageAccessGranted, isFalse);
      expect(
        DeviceInfo.fromMap(const {
          'usageAccessGranted': true,
        }).usageAccessGranted,
        isTrue,
      );
    });
  });
}
