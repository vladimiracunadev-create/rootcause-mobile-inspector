/// Motor de reglas — Dart puro, 100 % testeable sin dispositivo.
///
/// Misma filosofía que el rule engine del RootCause de escritorio: detectar
/// distorsiones anómalas de recursos como primer indicio, con evidencia y
/// recomendación, sin pretender ser un antivirus.
library;

import 'models.dart';

/// Umbrales centralizados: configurables y forzables desde tests.
class RuleThresholds {
  const RuleThresholds({
    this.memoryWarningRatio = 0.20,
    this.memoryCriticalRatio = 0.10,
    this.storageWarningRatio = 0.15,
    this.storageCriticalRatio = 0.05,
    this.batteryTempWarningCelsius = 40.0,
    this.batteryTempCriticalCelsius = 45.0,
    this.riskyAppScoreThreshold = 8,
    this.riskyAppsCriticalCount = 5,
  });

  final double memoryWarningRatio;
  final double memoryCriticalRatio;
  final double storageWarningRatio;
  final double storageCriticalRatio;
  final double batteryTempWarningCelsius;
  final double batteryTempCriticalCelsius;
  final int riskyAppScoreThreshold;
  final int riskyAppsCriticalCount;
}

class RuleEngine {
  const RuleEngine({this.thresholds = const RuleThresholds()});

  final RuleThresholds thresholds;

  Verdict evaluate(Snapshot snapshot) {
    final findings = <Finding>[
      ..._memory(snapshot),
      ..._storage(snapshot),
      ..._battery(snapshot),
      ..._apps(snapshot),
      ..._rootIndicators(snapshot),
    ];

    var severity = Severity.normal;
    var score = 0;
    for (final f in findings) {
      if (f.severity.index > severity.index) severity = f.severity;
      score += _weight(f.severity);
    }
    return Verdict(severity: severity, score: score, findings: findings);
  }

  List<Finding> _memory(Snapshot s) {
    final ratio = s.memory.availableRatio;
    final pct = (ratio * 100).round().toString();
    if (s.memory.lowMemory || ratio < thresholds.memoryCriticalRatio) {
      return [
        Finding(id: 'mem-pressure', severity: Severity.critical, args: [pct]),
      ];
    }
    if (ratio < thresholds.memoryWarningRatio) {
      return [
        Finding(id: 'mem-pressure', severity: Severity.warning, args: [pct]),
      ];
    }
    return const [];
  }

  List<Finding> _storage(Snapshot s) {
    final ratio = s.storage.freeRatio;
    final pct = (ratio * 100).round().toString();
    if (ratio < thresholds.storageCriticalRatio) {
      return [
        Finding(id: 'storage-low', severity: Severity.critical, args: [pct]),
      ];
    }
    if (ratio < thresholds.storageWarningRatio) {
      return [
        Finding(id: 'storage-low', severity: Severity.warning, args: [pct]),
      ];
    }
    return const [];
  }

  List<Finding> _battery(Snapshot s) {
    final findings = <Finding>[];
    if (s.battery.temperatureAvailable) {
      final temp = s.battery.temperatureCelsius;
      final tempText = temp.toStringAsFixed(1);
      if (temp >= thresholds.batteryTempCriticalCelsius) {
        findings.add(
          Finding(
            id: 'battery-temp',
            severity: Severity.critical,
            args: [tempText],
          ),
        );
      } else if (temp >= thresholds.batteryTempWarningCelsius) {
        findings.add(
          Finding(
            id: 'battery-temp',
            severity: Severity.warning,
            args: [tempText],
          ),
        );
      }
    }
    if (!s.battery.healthy) {
      findings.add(
        Finding(
          id: 'battery-health',
          severity: Severity.warning,
          args: [s.battery.healthLabel],
        ),
      );
    }
    return findings;
  }

  List<Finding> _apps(Snapshot s) {
    final risky = s.apps
        .where((a) => a.riskScore >= thresholds.riskyAppScoreThreshold)
        .toList();
    if (risky.isEmpty) return const [];
    final severity = risky.length >= thresholds.riskyAppsCriticalCount
        ? Severity.critical
        : Severity.warning;
    final names = risky.take(3).map((a) => a.label).join(', ');
    return [
      Finding(
        id: 'risky-apps',
        severity: severity,
        args: [risky.length.toString(), names],
      ),
    ];
  }

  List<Finding> _rootIndicators(Snapshot s) {
    final indicators = s.device.rootIndicators;
    if (indicators.isEmpty) return const [];
    return [
      Finding(
        id: 'root-indicators',
        severity: Severity.warning,
        args: [indicators.length.toString(), indicators.join(', ')],
      ),
    ];
  }

  int _weight(Severity severity) => switch (severity) {
    Severity.normal => 0,
    Severity.warning => 3,
    Severity.critical => 10,
  };
}
