/// Export forense JSON — Dart puro (`dart:convert`).
///
/// Los ids de hallazgo se conservan neutrales al idioma para que la
/// evidencia sea comparable entre dispositivos y con la edición Windows.
library;

import 'dart:convert';

import 'models.dart';

class SnapshotJson {
  static const int schemaVersion = 1;

  static Map<String, Object?> toMap(Snapshot s, Verdict v) => {
    'schemaVersion': schemaVersion,
    'timestampMillis': s.timestampMillis,
    'verdict': {'severity': v.severity.name, 'score': v.score},
    'findings': [
      for (final f in v.findings)
        {'id': f.id, 'severity': f.severity.name, 'args': f.args},
    ],
    'memory': {
      'totalBytes': s.memory.totalBytes,
      'availableBytes': s.memory.availableBytes,
      'lowMemory': s.memory.lowMemory,
    },
    'storage': {
      'totalBytes': s.storage.totalBytes,
      'freeBytes': s.storage.freeBytes,
      'appCacheBytes': s.storage.appCacheBytes,
    },
    'battery': {
      'levelPercent': s.battery.levelPercent,
      'charging': s.battery.charging,
      'temperatureCelsius': s.battery.temperatureCelsius,
      'temperatureAvailable': s.battery.temperatureAvailable,
      'voltageMillivolts': s.battery.voltageMillivolts,
      'healthy': s.battery.healthy,
      'healthLabel': s.battery.healthLabel,
    },
    'network': {
      'connected': s.network.connected,
      'transport': s.network.transport,
      'vpnActive': s.network.vpnActive,
      'metered': s.network.metered,
      'downstreamKbps': s.network.downstreamKbps,
      'upstreamKbps': s.network.upstreamKbps,
      'totalRxBytes': s.network.totalRxBytes,
      'totalTxBytes': s.network.totalTxBytes,
    },
    'apps': [
      for (final a in s.apps)
        {
          'packageName': a.packageName,
          'label': a.label,
          'versionName': a.versionName,
          'riskScore': a.riskScore,
          'severity': a.severity.name,
          'sideloaded': a.sideloaded,
          'dangerousPermissions': a.dangerousPermissions,
          'specialFlags': a.specialFlags,
        },
    ],
    'device': {
      'manufacturer': s.device.manufacturer,
      'model': s.device.model,
      'osVersion': s.device.osVersion,
      'sdkInt': s.device.sdkInt,
      'securityPatch': s.device.securityPatch,
      'cpuCores': s.device.cpuCores,
      'uptimeMillis': s.device.uptimeMillis,
      'rootIndicators': s.device.rootIndicators,
      'appsAuditSupported': s.device.appsAuditSupported,
    },
  };

  static String toJson(Snapshot s, Verdict v) =>
      const JsonEncoder.withIndent('  ').convert(toMap(s, v));

  /// Una línea compacta para el historial JSON Lines.
  static String toJsonLine(Snapshot s, Verdict v) => jsonEncode(toMap(s, v));
}
