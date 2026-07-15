import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';

import 'helpers.dart';

void main() {
  group('Snapshot.fromCollectorMap — degradación segura', () {
    test('mapa vacío del nativo → snapshot neutro sin crash', () {
      final s = Snapshot.fromCollectorMap(const {}, timestampMillis: 123);
      expect(s.timestampMillis, 123);
      expect(s.memory.totalBytes, 0);
      expect(s.storage.freeRatio, 0.0);
      expect(s.battery.healthy, isTrue);
      expect(s.network.transport, 'none');
      expect(s.apps, isEmpty);
      expect(s.device.appsAuditSupported, isFalse);
    });

    test('tipos inesperados degradan a defaults, no a crash', () {
      final s = Snapshot.fromCollectorMap(const {
        'memory': {'totalBytes': 'texto', 'availableBytes': null},
        'apps': ['no-soy-mapa', 42],
        'device': {'rootIndicators': 'no-soy-lista'},
      }, timestampMillis: 1);
      expect(s.memory.totalBytes, 0);
      expect(s.apps, isEmpty);
      expect(s.device.rootIndicators, isEmpty);
    });

    test('mapa completo se parsea con fidelidad', () {
      final s = Snapshot.fromCollectorMap(const {
        'memory': {
          'totalBytes': 1000,
          'availableBytes': 400,
          'lowMemory': false,
        },
        'battery': {
          'levelPercent': 77,
          'charging': true,
          'temperatureCelsius': 33.5,
          'temperatureAvailable': true,
          'voltageMillivolts': 4200,
          'healthy': true,
          'healthLabel': 'good',
        },
        'device': {
          'manufacturer': 'Google',
          'model': 'Pixel 8',
          'osVersion': '15',
          'sdkInt': 35,
          'securityPatch': '2026-05-05',
          'cpuCores': 9,
          'uptimeMillis': 100,
          'rootIndicators': <String>[],
          'appsAuditSupported': true,
        },
      }, timestampMillis: 5);
      expect(s.memory.availableRatio, closeTo(0.4, 0.001));
      expect(s.battery.levelPercent, 77);
      expect(s.battery.temperatureCelsius, closeTo(33.5, 0.001));
      expect(s.device.model, 'Pixel 8');
      expect(s.device.appsAuditSupported, isTrue);
    });
  });

  group('AppRisk — política de puntaje', () {
    test('+1 por permiso peligroso', () {
      final app = buildAppRisk(
        dangerousPermissions: const ['CAMERA', 'RECORD_AUDIO'],
      );
      expect(app.riskScore, 2);
      expect(app.severity, Severity.normal);
    });

    test('overlay e installs-packages suman +3 cada uno', () {
      final app = buildAppRisk(
        specialFlags: const ['overlay', 'installs-packages'],
      );
      expect(app.riskScore, 6);
    });

    test('sideload suma +2 y añade el flag visible', () {
      final app = buildAppRisk(sideloaded: true);
      expect(app.riskScore, 2);
      expect(app.specialFlags, contains('sideloaded'));
    });

    test('score ≥ 8 → WARNING; ≥ 12 → CRITICAL', () {
      final warning = buildAppRisk(
        dangerousPermissions: const ['A', 'B', 'C'],
        specialFlags: const ['overlay'],
        sideloaded: true,
      ); // 3 + 3 + 2 = 8
      expect(warning.severity, Severity.warning);

      final critical = buildAppRisk(
        dangerousPermissions: const ['A', 'B', 'C', 'D'],
        specialFlags: const ['overlay', 'installs-packages'],
        sideloaded: true,
      ); // 4 + 6 + 2 = 12
      expect(critical.severity, Severity.critical);
    });
  });

  test('severityFromName es tolerante a mayúsculas y desconocidos', () {
    expect(severityFromName('CRITICAL'), Severity.critical);
    expect(severityFromName('Warning'), Severity.warning);
    expect(severityFromName('lo-que-sea'), Severity.normal);
  });
}
