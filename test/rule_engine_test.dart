import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';

import 'helpers.dart';

void main() {
  const engine = RuleEngine();

  group('RuleEngine — veredicto global', () {
    test('dispositivo sano → NORMAL sin hallazgos y puntaje 0', () {
      final verdict = engine.evaluate(buildSnapshot());
      expect(verdict.severity, Severity.normal);
      expect(verdict.findings, isEmpty);
      expect(verdict.score, 0);
    });

    test('la severidad global es el máximo de los hallazgos', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          // warning por almacenamiento (10 % libre)
          storage: const StorageInfo(
            totalBytes: 100,
            freeBytes: 10,
            appCacheBytes: 0,
          ),
          // critical por memoria (5 % disponible)
          memory: const MemoryInfo(
            totalBytes: 100,
            availableBytes: 5,
            lowMemory: false,
          ),
        ),
      );
      expect(verdict.severity, Severity.critical);
      // critical (10) + warning (3)
      expect(verdict.score, 13);
    });
  });

  group('RuleEngine — memoria', () {
    test('memoria disponible < 10 % → mem-pressure CRITICAL', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          memory: const MemoryInfo(
            totalBytes: 100,
            availableBytes: 8,
            lowMemory: false,
          ),
        ),
      );
      final f = verdict.findings.single;
      expect(f.id, 'mem-pressure');
      expect(f.severity, Severity.critical);
      expect(f.args.first, '8');
    });

    test('flag lowMemory del SO → CRITICAL aunque el ratio sea alto', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          memory: const MemoryInfo(
            totalBytes: 100,
            availableBytes: 50,
            lowMemory: true,
          ),
        ),
      );
      expect(verdict.findings.single.severity, Severity.critical);
    });

    test('memoria disponible < 20 % → mem-pressure WARNING', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          memory: const MemoryInfo(
            totalBytes: 100,
            availableBytes: 15,
            lowMemory: false,
          ),
        ),
      );
      expect(verdict.findings.single.severity, Severity.warning);
    });
  });

  group('RuleEngine — almacenamiento', () {
    test('libre < 5 % → storage-low CRITICAL', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          storage: const StorageInfo(
            totalBytes: 100,
            freeBytes: 3,
            appCacheBytes: 0,
          ),
        ),
      );
      final f = verdict.findings.single;
      expect(f.id, 'storage-low');
      expect(f.severity, Severity.critical);
    });

    test('libre < 15 % → storage-low WARNING', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          storage: const StorageInfo(
            totalBytes: 100,
            freeBytes: 12,
            appCacheBytes: 0,
          ),
        ),
      );
      expect(verdict.findings.single.severity, Severity.warning);
    });
  });

  group('RuleEngine — batería', () {
    test('≥ 45 °C → battery-temp CRITICAL', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          battery: const BatteryInfo(
            levelPercent: 50,
            charging: false,
            temperatureCelsius: 46.5,
            temperatureAvailable: true,
            voltageMillivolts: 4000,
            healthy: true,
            healthLabel: 'good',
          ),
        ),
      );
      final f = verdict.findings.single;
      expect(f.id, 'battery-temp');
      expect(f.severity, Severity.critical);
      expect(f.args.first, '46.5');
    });

    test(
      'temperatura no disponible (iOS) → sin hallazgo aunque el valor sea 0',
      () {
        final verdict = engine.evaluate(
          buildSnapshot(
            battery: const BatteryInfo(
              levelPercent: 50,
              charging: false,
              temperatureCelsius: 0.0,
              temperatureAvailable: false,
              voltageMillivolts: 0,
              healthy: true,
              healthLabel: 'unknown',
            ),
          ),
        );
        expect(verdict.findings.where((f) => f.id == 'battery-temp'), isEmpty);
      },
    );

    test(
      'salud degradada → battery-health WARNING con etiqueta como evidencia',
      () {
        final verdict = engine.evaluate(
          buildSnapshot(
            battery: const BatteryInfo(
              levelPercent: 50,
              charging: false,
              temperatureCelsius: 30.0,
              temperatureAvailable: true,
              voltageMillivolts: 4000,
              healthy: false,
              healthLabel: 'overheat',
            ),
          ),
        );
        final f = verdict.findings.single;
        expect(f.id, 'battery-health');
        expect(f.args, ['overheat']);
      },
    );
  });

  group('RuleEngine — apps riesgosas', () {
    AppRisk risky(String name) => buildAppRisk(
      packageName: 'com.risky.$name',
      label: name,
      dangerousPermissions: const [
        'CAMERA',
        'RECORD_AUDIO',
        'ACCESS_FINE_LOCATION',
      ],
      specialFlags: const ['overlay', 'installs-packages'],
    );

    test('1 app con score alto → risky-apps WARNING', () {
      final verdict = engine.evaluate(buildSnapshot(apps: [risky('a')]));
      final f = verdict.findings.single;
      expect(f.id, 'risky-apps');
      expect(f.severity, Severity.warning);
      expect(f.args.first, '1');
    });

    test('5 apps con score alto → risky-apps CRITICAL', () {
      final verdict = engine.evaluate(
        buildSnapshot(apps: List.generate(5, (i) => risky('app$i'))),
      );
      expect(verdict.findings.single.severity, Severity.critical);
    });

    test('apps benignas no generan hallazgo', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          apps: [
            buildAppRisk(dangerousPermissions: const ['CAMERA']),
          ],
        ),
      );
      expect(verdict.findings, isEmpty);
    });
  });

  group('RuleEngine — root/jailbreak', () {
    test('indicadores presentes → root-indicators WARNING con evidencia', () {
      final verdict = engine.evaluate(
        buildSnapshot(
          device: const DeviceInfo(
            manufacturer: 'Test',
            model: 'Unit',
            osVersion: '14',
            sdkInt: 34,
            securityPatch: '2026-06-01',
            cpuCores: 8,
            uptimeMillis: 0,
            rootIndicators: ['/system/xbin/su', 'build:test-keys'],
            appsAuditSupported: true,
          ),
        ),
      );
      final f = verdict.findings.single;
      expect(f.id, 'root-indicators');
      expect(f.severity, Severity.warning);
      expect(f.args, ['2', '/system/xbin/su, build:test-keys']);
    });
  });

  group('RuleThresholds — umbrales personalizados', () {
    test('un umbral más estricto cambia el veredicto', () {
      const strict = RuleEngine(
        thresholds: RuleThresholds(memoryWarningRatio: 0.60),
      );
      final verdict = strict.evaluate(
        buildSnapshot(
          memory: const MemoryInfo(
            totalBytes: 100,
            availableBytes: 50,
            lowMemory: false,
          ),
        ),
      );
      expect(verdict.findings.single.id, 'mem-pressure');
      expect(verdict.findings.single.severity, Severity.warning);
    });
  });
}
