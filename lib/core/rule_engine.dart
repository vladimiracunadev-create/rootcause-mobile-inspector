/// Motor de reglas — Dart puro, 100 % testeable sin dispositivo.
///
/// Misma filosofía que el rule engine del RootCause de escritorio: detectar
/// distorsiones anómalas de recursos como primer indicio, con evidencia y
/// recomendación, sin pretender ser un antivirus.
library;

import 'history_store.dart';
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
    this.patchWarningDays = 180,
    this.patchCriticalDays = 365,
  });

  final double memoryWarningRatio;
  final double memoryCriticalRatio;
  final double storageWarningRatio;
  final double storageCriticalRatio;
  final double batteryTempWarningCelsius;
  final double batteryTempCriticalCelsius;
  final int riskyAppScoreThreshold;
  final int riskyAppsCriticalCount;

  /// Edad del parche de seguridad (días) para advertencia y crítico.
  final int patchWarningDays;
  final int patchCriticalDays;
}

class RuleEngine {
  const RuleEngine({this.thresholds = const RuleThresholds()});

  final RuleThresholds thresholds;

  /// [history] son las capturas previas (la más reciente primero) para la
  /// regla de tendencia; sin historial la regla simplemente se omite.
  /// [newApps] son las apps que el baseline detectó como instaladas desde
  /// la captura anterior (equivalente móvil del `persistence-change` de la
  /// edición Windows).
  Verdict evaluate(
    Snapshot snapshot, {
    List<HistoryRow> history = const [],
    List<AppRisk> newApps = const [],
  }) {
    final findings = <Finding>[
      ..._memory(snapshot),
      ..._storage(snapshot),
      ..._battery(snapshot),
      ..._apps(snapshot),
      ..._newApps(newApps),
      ..._rootIndicators(snapshot),
      ..._patchAge(snapshot),
      ..._trend(snapshot, history),
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

  /// Apps instaladas desde la captura anterior. Es transitorio a propósito:
  /// aparece en la captura que detecta la instalación y el baseline la
  /// absorbe después — como la alerta de persistencia del escritorio.
  /// WARNING siempre: una instalación que tú hiciste se descarta en dos
  /// segundos; una que no reconoces es exactamente el indicio que buscamos.
  List<Finding> _newApps(List<AppRisk> newApps) {
    if (newApps.isEmpty) return const [];
    final names = newApps.take(3).map((a) => a.label).join(', ');
    final risky = newApps.where(
      (a) => a.severity != Severity.normal || a.sideloaded,
    );
    return [
      Finding(
        id: 'new-apps',
        severity: Severity.warning,
        args: [newApps.length.toString(), names, risky.length.toString()],
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

  /// Parche de seguridad antiguo: cada mes sin parches acumula
  /// vulnerabilidades CONOCIDAS y públicas. Solo se evalúa si la
  /// plataforma expone la fecha en formato parseable (Android:
  /// YYYY-MM-DD); iOS reporta su versión, no una fecha → regla omitida,
  /// no inventada.
  List<Finding> _patchAge(Snapshot s) {
    final patchDate = DateTime.tryParse(s.device.securityPatch);
    if (patchDate == null) return const [];
    final now = DateTime.fromMillisecondsSinceEpoch(s.timestampMillis);
    final days = now.difference(patchDate).inDays;
    if (days >= thresholds.patchCriticalDays) {
      return [
        Finding(
          id: 'patch-old',
          severity: Severity.critical,
          args: ['$days', s.device.securityPatch],
        ),
      ];
    }
    if (days >= thresholds.patchWarningDays) {
      return [
        Finding(
          id: 'patch-old',
          severity: Severity.warning,
          args: ['$days', s.device.securityPatch],
        ),
      ];
    }
    return const [];
  }

  /// Carga en ascenso: la razón de existir del sistema aplicada al tiempo.
  /// Una caída sostenida de memoria disponible o disco libre a lo largo de
  /// varias capturas es el indicio temprano, aunque ningún umbral absoluto
  /// haya disparado todavía.
  ///
  /// Requiere al menos [trendMinPoints] puntos (capturas previas + la
  /// actual) dentro de [trendWindow]; cada paso puede mejorar como máximo
  /// [trendStepTolerancePct] (ruido) y la caída total debe superar
  /// [trendDropPct] puntos porcentuales.
  static const int trendMinPoints = 4;
  static const Duration trendWindow = Duration(hours: 6);
  static const int trendStepTolerancePct = 2;
  static const int trendDropPct = 15;

  List<Finding> _trend(Snapshot s, List<HistoryRow> history) {
    if (history.length < trendMinPoints - 1) return const [];
    final cutoff = s.timestampMillis - trendWindow.inMilliseconds;
    final recent = history
        .where((r) => r.timestampMillis >= cutoff)
        .take(8)
        .toList();
    if (recent.length < trendMinPoints - 1) return const [];

    final findings = <Finding>[];
    final memSeries = [
      ...recent.reversed.map((r) => r.memAvailablePct),
      (s.memory.availableRatio * 100).round(),
    ];
    final memDrop = _sustainedDrop(memSeries);
    if (memDrop != null) {
      findings.add(
        Finding(
          id: 'load-rising',
          severity: Severity.warning,
          args: ['memory', '${memSeries.first}', '${memSeries.last}'],
        ),
      );
    }
    final storageSeries = [
      ...recent.reversed.map((r) => r.storageFreePct),
      (s.storage.freeRatio * 100).round(),
    ];
    final storageDrop = _sustainedDrop(storageSeries);
    if (storageDrop != null) {
      findings.add(
        Finding(
          id: 'load-rising',
          severity: Severity.warning,
          args: ['storage', '${storageSeries.first}', '${storageSeries.last}'],
        ),
      );
    }
    return findings;
  }

  /// Caída total (en puntos porcentuales) si la serie oldest→newest baja de
  /// forma sostenida; `null` si no hay tendencia.
  int? _sustainedDrop(List<int> series) {
    if (series.length < trendMinPoints) return null;
    for (var i = 1; i < series.length; i++) {
      if (series[i] - series[i - 1] > trendStepTolerancePct) return null;
    }
    final drop = series.first - series.last;
    return drop >= trendDropPct ? drop : null;
  }

  int _weight(Severity severity) => switch (severity) {
    Severity.normal => 0,
    Severity.warning => 3,
    Severity.critical => 10,
  };
}
