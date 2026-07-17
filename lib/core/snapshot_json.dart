/// Export forense JSON — Dart puro (`dart:convert`).
///
/// Los ids de hallazgo se conservan neutrales al idioma para que la
/// evidencia sea comparable entre dispositivos y con la edición Windows.
library;

import 'dart:convert';

import 'baseline_store.dart';
import 'models.dart';

class SnapshotJson {
  /// Política de esquema: campos NUEVOS se agregan sin subir la versión
  /// (los lectores ignoran lo desconocido); solo un cambio que rompa la
  /// lectura de campos existentes sube este número. Documentado en
  /// docs/ARCHITECTURE.md.
  static const int schemaVersion = 1;

  static Map<String, Object?> toMap(
    Snapshot s,
    Verdict v, {
    BaselineDiff? diff,
  }) => {
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
      'volumes': [
        for (final v in s.storage.volumes)
          {
            'label': v.label,
            'totalBytes': v.totalBytes,
            'freeBytes': v.freeBytes,
            'removable': v.removable,
          },
      ],
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
          'foregroundMillis24h': a.foregroundMillis24h,
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
      'vendorSkin': s.device.vendorSkin,
      'usageAccessGranted': s.device.usageAccessGranted,
    },
    if (diff != null && !diff.isEmpty)
      'baselineChanges': {
        'new': [for (final a in diff.newApps) a.packageName],
        'updated': [for (final a in diff.updatedApps) a.packageName],
        'removed': diff.removedPackages,
      },
  };

  static String toJson(Snapshot s, Verdict v, {BaselineDiff? diff}) =>
      const JsonEncoder.withIndent('  ').convert(toMap(s, v, diff: diff));

  /// Una línea compacta (sin sellar); el sellado lo hace HistoryStore.
  static String toJsonLine(Snapshot s, Verdict v) => jsonEncode(toMap(s, v));
}
