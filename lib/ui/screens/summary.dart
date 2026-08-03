/// Pestaña Resumen: el semáforo global y los hallazgos con evidencia.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../widgets.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.strings,
    this.onOpenSystemScreen,
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final AppStrings strings;
  final void Function(String screen)? onOpenSystemScreen;

  /// Pantalla del sistema que resuelve cada hallazgo, si existe una directa.
  (String, String)? _actionFor(Finding f) => switch (f.id) {
    'storage-low' => ('free-space', strings.actionFreeSpace),
    'battery-temp' ||
    'battery-health' => ('battery', strings.actionBatteryUsage),
    'patch-old' => ('system-update', strings.actionSystemUpdate),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final mem = snapshot.memory;
    final st = snapshot.storage;
    final bat = snapshot.battery;
    return ListView(
      children: [
        VerdictBanner(verdict: verdict, strings: strings),
        if (verdict.findings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(strings.findingsNone),
          )
        else
          ...verdict.findings.map((f) {
            final action = _actionFor(f);
            return FindingCard(
              finding: f,
              strings: strings,
              actionLabel: action?.$2,
              onAction: action == null || onOpenSystemScreen == null
                  ? null
                  : () => onOpenSystemScreen!(action.$1),
            );
          }),
        SectionCard(
          title: strings.memTitle,
          children: [
            LinearProgressIndicator(
              value: (1.0 - mem.availableRatio).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            InfoRow(label: strings.memUsed, value: formatBytes(mem.usedBytes)),
            InfoRow(
              label: strings.memAvailable,
              value: formatBytes(mem.availableBytes),
            ),
            InfoRow(
              label: strings.memTotal,
              value: formatBytes(mem.totalBytes),
            ),
          ],
        ),
        SectionCard(
          title: strings.storageTitle,
          children: [
            LinearProgressIndicator(
              value: (1.0 - st.freeRatio).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            InfoRow(
              label: strings.storageFree,
              value: formatBytes(st.freeBytes),
            ),
            InfoRow(
              label: strings.storageTotal,
              value: formatBytes(st.totalBytes),
            ),
          ],
        ),
        SectionCard(
          title: strings.batteryTitle,
          children: [
            InfoRow(label: strings.batteryLevel, value: '${bat.levelPercent}%'),
            InfoRow(
              label: strings.batteryState,
              value: bat.charging
                  ? strings.batteryCharging
                  : strings.batteryDischarging,
            ),
            InfoRow(
              label: strings.batteryTemp,
              value: bat.temperatureAvailable
                  ? '${bat.temperatureCelsius.toStringAsFixed(1)} °C'
                  : strings.notAvailableOnPlatform,
            ),
            InfoRow(
              label: strings.batteryHealth,
              value: bat.temperatureAvailable
                  ? bat.healthLabel
                  : strings.notAvailableOnPlatform,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            strings.snapshotTaken(formatTimestamp(snapshot.timestampMillis)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
