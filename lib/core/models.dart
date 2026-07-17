/// Modelos del núcleo compartido — Dart puro, sin dependencias de Flutter.
///
/// Los colectores nativos (Kotlin/Swift) entregan mapas por MethodChannel;
/// aquí se validan con defaults seguros: un campo ausente degrada a valor
/// neutro, nunca a crash.
library;

/// Severidad compartida por hallazgos, apps y veredicto global.
enum Severity { normal, warning, critical }

Severity severityFromName(String name) => switch (name.toLowerCase()) {
  'critical' => Severity.critical,
  'warning' => Severity.warning,
  _ => Severity.normal,
};

int _asInt(Object? v) => switch (v) {
  int i => i,
  num n => n.toInt(),
  _ => 0,
};

double _asDouble(Object? v) => switch (v) {
  double d => d,
  num n => n.toDouble(),
  _ => 0.0,
};

bool _asBool(Object? v) => v == true;

String _asString(Object? v, [String fallback = '?']) =>
    v is String && v.isNotEmpty ? v : fallback;

List<String> _asStringList(Object? v) =>
    v is List ? v.whereType<String>().toList() : const [];

class MemoryInfo {
  const MemoryInfo({
    required this.totalBytes,
    required this.availableBytes,
    required this.lowMemory,
  });

  factory MemoryInfo.fromMap(Map<Object?, Object?> map) => MemoryInfo(
    totalBytes: _asInt(map['totalBytes']),
    availableBytes: _asInt(map['availableBytes']),
    lowMemory: _asBool(map['lowMemory']),
  );

  final int totalBytes;
  final int availableBytes;
  final bool lowMemory;

  int get usedBytes =>
      totalBytes - availableBytes < 0 ? 0 : totalBytes - availableBytes;

  double get availableRatio =>
      totalBytes > 0 ? availableBytes / totalBytes : 0.0;
}

/// Volumen de almacenamiento adicional (tarjeta SD, USB OTG). El volumen
/// interno de datos se reporta aparte en [StorageInfo]; esta lista puede
/// estar vacía — un teléfono sin tarjeta es un caso normal, no un error.
class VolumeInfo {
  const VolumeInfo({
    required this.label,
    required this.totalBytes,
    required this.freeBytes,
    required this.removable,
  });

  factory VolumeInfo.fromMap(Map<Object?, Object?> map) => VolumeInfo(
    label: _asString(map['label'], 'SD'),
    totalBytes: _asInt(map['totalBytes']),
    freeBytes: _asInt(map['freeBytes']),
    removable: _asBool(map['removable']),
  );

  final String label;
  final int totalBytes;
  final int freeBytes;
  final bool removable;

  double get freeRatio => totalBytes > 0 ? freeBytes / totalBytes : 0.0;
}

class StorageInfo {
  const StorageInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.appCacheBytes,
    this.volumes = const [],
  });

  factory StorageInfo.fromMap(Map<Object?, Object?> map) => StorageInfo(
    totalBytes: _asInt(map['totalBytes']),
    freeBytes: _asInt(map['freeBytes']),
    appCacheBytes: _asInt(map['appCacheBytes']),
    volumes: map['volumes'] is List
        ? (map['volumes']! as List)
              .whereType<Map<Object?, Object?>>()
              .map(VolumeInfo.fromMap)
              .toList()
        : const [],
  );

  final int totalBytes;
  final int freeBytes;
  final int appCacheBytes;

  /// Volúmenes adicionales detectados (SD/USB); vacío si no hay.
  final List<VolumeInfo> volumes;

  double get freeRatio => totalBytes > 0 ? freeBytes / totalBytes : 0.0;
}

class BatteryInfo {
  const BatteryInfo({
    required this.levelPercent,
    required this.charging,
    required this.temperatureCelsius,
    required this.temperatureAvailable,
    required this.voltageMillivolts,
    required this.healthy,
    required this.healthLabel,
  });

  factory BatteryInfo.fromMap(Map<Object?, Object?> map) => BatteryInfo(
    levelPercent: _asInt(map['levelPercent']),
    charging: _asBool(map['charging']),
    temperatureCelsius: _asDouble(map['temperatureCelsius']),
    temperatureAvailable: _asBool(map['temperatureAvailable']),
    voltageMillivolts: _asInt(map['voltageMillivolts']),
    healthy: map['healthy'] == null ? true : _asBool(map['healthy']),
    healthLabel: _asString(map['healthLabel'], 'unknown'),
  );

  final int levelPercent;
  final bool charging;
  final double temperatureCelsius;

  /// iOS no expone temperatura de batería; con `false` la regla se omite.
  final bool temperatureAvailable;
  final int voltageMillivolts;
  final bool healthy;
  final String healthLabel;
}

class NetworkStatus {
  const NetworkStatus({
    required this.connected,
    required this.transport,
    required this.vpnActive,
    required this.metered,
    required this.downstreamKbps,
    required this.upstreamKbps,
    required this.totalRxBytes,
    required this.totalTxBytes,
  });

  factory NetworkStatus.fromMap(Map<Object?, Object?> map) => NetworkStatus(
    connected: _asBool(map['connected']),
    transport: _asString(map['transport'], 'none'),
    vpnActive: _asBool(map['vpnActive']),
    metered: _asBool(map['metered']),
    downstreamKbps: _asInt(map['downstreamKbps']),
    upstreamKbps: _asInt(map['upstreamKbps']),
    totalRxBytes: _asInt(map['totalRxBytes']),
    totalTxBytes: _asInt(map['totalTxBytes']),
  );

  final bool connected;
  final String transport;
  final bool vpnActive;
  final bool metered;
  final int downstreamKbps;
  final int upstreamKbps;
  final int totalRxBytes;
  final int totalTxBytes;
}

class AppRisk {
  const AppRisk({
    required this.packageName,
    required this.label,
    required this.versionName,
    required this.dangerousPermissions,
    required this.specialFlags,
    required this.sideloaded,
    required this.riskScore,
    required this.severity,
  });

  /// El puntaje y la severidad se calculan aquí (Dart compartido) a partir
  /// de la evidencia cruda del nativo, para que la política de riesgo sea
  /// una sola y testeable.
  factory AppRisk.fromMap(Map<Object?, Object?> map) {
    final dangerous = _asStringList(map['dangerousPermissions']);
    final flags = _asStringList(map['specialFlags']);
    final sideloaded = _asBool(map['sideloaded']);

    var score = dangerous.length;
    if (flags.contains('overlay')) score += 3;
    if (flags.contains('installs-packages')) score += 3;
    if (flags.contains('device-admin')) score += 2;
    if (sideloaded) score += 2;

    final severity = score >= 12
        ? Severity.critical
        : score >= 8
        ? Severity.warning
        : Severity.normal;

    return AppRisk(
      packageName: _asString(map['packageName']),
      label: _asString(map['label']),
      versionName: _asString(map['versionName']),
      dangerousPermissions: dangerous,
      specialFlags: sideloaded && !flags.contains('sideloaded')
          ? [...flags, 'sideloaded']
          : flags,
      sideloaded: sideloaded,
      riskScore: score,
      severity: severity,
    );
  }

  final String packageName;
  final String label;
  final String versionName;
  final List<String> dangerousPermissions;
  final List<String> specialFlags;
  final bool sideloaded;
  final int riskScore;
  final Severity severity;
}

class DeviceInfo {
  const DeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.osVersion,
    required this.sdkInt,
    required this.securityPatch,
    required this.cpuCores,
    required this.uptimeMillis,
    required this.rootIndicators,
    required this.appsAuditSupported,
  });

  factory DeviceInfo.fromMap(Map<Object?, Object?> map) => DeviceInfo(
    manufacturer: _asString(map['manufacturer']),
    model: _asString(map['model']),
    osVersion: _asString(map['osVersion']),
    sdkInt: _asInt(map['sdkInt']),
    securityPatch: _asString(map['securityPatch']),
    cpuCores: _asInt(map['cpuCores']),
    uptimeMillis: _asInt(map['uptimeMillis']),
    rootIndicators: _asStringList(map['rootIndicators']),
    appsAuditSupported: _asBool(map['appsAuditSupported']),
  );

  final String manufacturer;
  final String model;
  final String osVersion;
  final int sdkInt;
  final String securityPatch;
  final int cpuCores;
  final int uptimeMillis;
  final List<String> rootIndicators;

  /// `false` en iOS: el SO no permite listar apps instaladas.
  final bool appsAuditSupported;
}

/// Captura completa del estado del dispositivo en un instante.
class Snapshot {
  const Snapshot({
    required this.timestampMillis,
    required this.memory,
    required this.storage,
    required this.battery,
    required this.network,
    required this.apps,
    required this.device,
  });

  factory Snapshot.fromCollectorMap(
    Map<Object?, Object?> map, {
    required int timestampMillis,
  }) {
    Map<Object?, Object?> sub(String key) =>
        map[key] is Map ? map[key]! as Map<Object?, Object?> : const {};
    final appsRaw = map['apps'];
    return Snapshot(
      timestampMillis: timestampMillis,
      memory: MemoryInfo.fromMap(sub('memory')),
      storage: StorageInfo.fromMap(sub('storage')),
      battery: BatteryInfo.fromMap(sub('battery')),
      network: NetworkStatus.fromMap(sub('network')),
      apps: appsRaw is List
          ? appsRaw
                .whereType<Map<Object?, Object?>>()
                .map(AppRisk.fromMap)
                .toList()
          : const [],
      device: DeviceInfo.fromMap(sub('device')),
    );
  }

  final int timestampMillis;
  final MemoryInfo memory;
  final StorageInfo storage;
  final BatteryInfo battery;
  final NetworkStatus network;
  final List<AppRisk> apps;
  final DeviceInfo device;
}

/// Hallazgo del motor de reglas. [id] es una clave estable e independiente
/// del idioma; la UI la traduce y el export JSON la conserva tal cual.
class Finding {
  const Finding({
    required this.id,
    required this.severity,
    this.args = const [],
  });

  final String id;
  final Severity severity;
  final List<String> args;
}

/// Veredicto global: semáforo + puntaje + hallazgos que lo sustentan.
class Verdict {
  const Verdict({
    required this.severity,
    required this.score,
    required this.findings,
  });

  final Severity severity;
  final int score;
  final List<Finding> findings;
}
