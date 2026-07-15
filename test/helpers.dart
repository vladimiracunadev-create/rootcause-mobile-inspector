/// Constructores de escenarios para los tests del núcleo.
library;

import 'package:rootcause_mobile_inspector/core/models.dart';

Snapshot buildSnapshot({
  MemoryInfo? memory,
  StorageInfo? storage,
  BatteryInfo? battery,
  NetworkStatus? network,
  List<AppRisk> apps = const [],
  DeviceInfo? device,
}) => Snapshot(
  timestampMillis: 1700000000000,
  memory:
      memory ??
      const MemoryInfo(
        totalBytes: 8 * 1024 * 1024 * 1024,
        availableBytes: 4 * 1024 * 1024 * 1024,
        lowMemory: false,
      ),
  storage:
      storage ??
      const StorageInfo(
        totalBytes: 128 * 1024 * 1024 * 1024,
        freeBytes: 64 * 1024 * 1024 * 1024,
        appCacheBytes: 1024,
      ),
  battery:
      battery ??
      const BatteryInfo(
        levelPercent: 80,
        charging: false,
        temperatureCelsius: 30.0,
        temperatureAvailable: true,
        voltageMillivolts: 4000,
        healthy: true,
        healthLabel: 'good',
      ),
  network:
      network ??
      const NetworkStatus(
        connected: true,
        transport: 'wifi',
        vpnActive: false,
        metered: false,
        downstreamKbps: 10000,
        upstreamKbps: 5000,
        totalRxBytes: 1000,
        totalTxBytes: 500,
      ),
  apps: apps,
  device:
      device ??
      const DeviceInfo(
        manufacturer: 'Test',
        model: 'Unit',
        osVersion: '14',
        sdkInt: 34,
        securityPatch: '2026-06-01',
        cpuCores: 8,
        uptimeMillis: 3600000,
        rootIndicators: [],
        appsAuditSupported: true,
      ),
);

AppRisk buildAppRisk({
  String packageName = 'com.example.app',
  String label = 'Example',
  List<String> dangerousPermissions = const [],
  List<String> specialFlags = const [],
  bool sideloaded = false,
}) => AppRisk.fromMap({
  'packageName': packageName,
  'label': label,
  'versionName': '1.0',
  'dangerousPermissions': dangerousPermissions,
  'specialFlags': specialFlags,
  'sideloaded': sideloaded,
});
