/// Pantallas de la app — consumen el snapshot + veredicto y los textos
/// bilingües. Sin lógica de negocio: eso vive en lib/core/.
library;

import 'package:flutter/material.dart';

import '../core/history_store.dart';
import '../core/models.dart';
import 'strings.dart';
import 'theme.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}

String formatUptime(int millis) {
  final totalMinutes = millis ~/ 60000;
  final days = totalMinutes ~/ (60 * 24);
  final hours = (totalMinutes ~/ 60) % 24;
  final minutes = totalMinutes % 60;
  return days > 0 ? '${days}d ${hours}h ${minutes}m' : '${hours}h ${minutes}m';
}

String formatTimestamp(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
}

class SeverityDot extends StatelessWidget {
  const SeverityDot({super.key, required this.severity, this.size = 12});

  final Severity severity;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: severityColor(severity),
      shape: BoxShape.circle,
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class VerdictBanner extends StatelessWidget {
  const VerdictBanner({
    super.key,
    required this.verdict,
    required this.strings,
  });

  final Verdict verdict;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final label = switch (verdict.severity) {
      Severity.normal => strings.verdictNormal,
      Severity.warning => strings.verdictWarning,
      Severity.critical => strings.verdictCritical,
    };
    return Card(
      margin: const EdgeInsets.all(12),
      color: severityColor(verdict.severity).withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SeverityDot(severity: verdict.severity, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    strings.verdictScore(verdict.score),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FindingCard extends StatelessWidget {
  const FindingCard({super.key, required this.finding, required this.strings});

  final Finding finding;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final reco = strings.findingReco(finding);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SeverityDot(severity: finding.severity),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.findingTitle(finding),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(strings.findingDetail(finding)),
            if (reco.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                strings.recommendation(reco),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.strings,
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final AppStrings strings;

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
          ...verdict.findings.map(
            (f) => FindingCard(finding: f, strings: strings),
          ),
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

class AppsScreen extends StatelessWidget {
  const AppsScreen({
    super.key,
    required this.apps,
    required this.auditSupported,
    required this.strings,
  });

  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (!auditSupported) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(strings.appsUnsupported),
      );
    }
    final risky = apps.where((a) => a.severity != Severity.normal).length;
    return ListView(
      children: [
        SectionCard(
          title: strings.appsTitle,
          children: [
            InfoRow(label: strings.appsTotal, value: apps.length.toString()),
            InfoRow(label: strings.appsRiskyCount, value: risky.toString()),
            const SizedBox(height: 4),
            Text(
              strings.appsHonestyNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        ...apps.map(
          (app) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeverityDot(severity: app.severity),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        strings.appRiskScore(app.riskScore),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    app.packageName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (app.dangerousPermissions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      strings.appPerms(app.dangerousPermissions.join(', ')),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (app.specialFlags.isNotEmpty)
                    Text(
                      strings.appFlags(app.specialFlags.join(', ')),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({
    super.key,
    required this.network,
    required this.strings,
  });

  final NetworkStatus network;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    String yesNo(bool v) => v ? strings.yes : strings.no;
    return ListView(
      children: [
        SectionCard(
          title: strings.networkTitle,
          children: [
            InfoRow(
              label: strings.netConnected,
              value: yesNo(network.connected),
            ),
            InfoRow(label: strings.netTransport, value: network.transport),
            InfoRow(label: strings.netVpn, value: yesNo(network.vpnActive)),
            InfoRow(label: strings.netMetered, value: yesNo(network.metered)),
            InfoRow(
              label: strings.netDown,
              value: '${network.downstreamKbps} kbps',
            ),
            InfoRow(
              label: strings.netUp,
              value: '${network.upstreamKbps} kbps',
            ),
          ],
        ),
        SectionCard(
          title: strings.netTrafficTitle,
          children: [
            InfoRow(
              label: strings.netRx,
              value: formatBytes(network.totalRxBytes),
            ),
            InfoRow(
              label: strings.netTx,
              value: formatBytes(network.totalTxBytes),
            ),
            const SizedBox(height: 4),
            Text(
              strings.netTrafficNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class StorageScreen extends StatelessWidget {
  const StorageScreen({
    super.key,
    required this.storage,
    required this.strings,
  });

  final StorageInfo storage;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final used = storage.totalBytes - storage.freeBytes;
    return ListView(
      children: [
        SectionCard(
          title: strings.storageTitle,
          children: [
            LinearProgressIndicator(
              value: (1.0 - storage.freeRatio).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            InfoRow(
              label: strings.storageFree,
              value: formatBytes(storage.freeBytes),
            ),
            InfoRow(
              label: strings.storageUsed,
              value: formatBytes(used < 0 ? 0 : used),
            ),
            InfoRow(
              label: strings.storageTotal,
              value: formatBytes(storage.totalBytes),
            ),
          ],
        ),
        SectionCard(
          title: strings.cacheTitle,
          children: [
            InfoRow(
              label: strings.cacheSize,
              value: formatBytes(storage.appCacheBytes),
            ),
            const SizedBox(height: 4),
            Text(
              strings.cacheNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.device, required this.strings});

  final DeviceInfo device;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SectionCard(
        title: strings.deviceTitle,
        children: [
          InfoRow(
            label: strings.deviceManufacturer,
            value: device.manufacturer,
          ),
          InfoRow(label: strings.deviceModel, value: device.model),
          InfoRow(
            label: strings.deviceOs,
            value: device.sdkInt > 0
                ? '${device.osVersion} (API ${device.sdkInt})'
                : device.osVersion,
          ),
          InfoRow(label: strings.devicePatch, value: device.securityPatch),
          InfoRow(
            label: strings.deviceCores,
            value: device.cpuCores.toString(),
          ),
          InfoRow(
            label: strings.deviceUptime,
            value: formatUptime(device.uptimeMillis),
          ),
        ],
      ),
      SectionCard(
        title: strings.rootTitle,
        children: [
          if (device.rootIndicators.isEmpty)
            Text(strings.rootNone)
          else ...[
            ...device.rootIndicators.map((i) => Text('• $i')),
            const SizedBox(height: 4),
            Text(
              strings.rootNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    ],
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.history,
    required this.strings,
  });

  final List<HistoryRow> history;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(strings.historyEmpty),
      );
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            strings.historyTitle(history.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...history.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SeverityDot(severity: row.severity),
                    const SizedBox(width: 8),
                    Text(
                      formatTimestamp(row.timestampMillis),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.verdictScore(row.score),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  strings.historyRow(
                    row.memAvailablePct,
                    row.storageFreePct,
                    row.riskyApps,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.strings,
    required this.productName,
    required this.version,
    required this.author,
    required this.license,
    required this.repository,
  });

  final AppStrings strings;
  final String productName;
  final String version;
  final String author;
  final String license;
  final String repository;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SectionCard(
        title: productName,
        children: [
          InfoRow(label: strings.aboutVersion, value: version),
          InfoRow(label: strings.aboutAuthor, value: author),
          InfoRow(label: strings.aboutLicense, value: license),
          const SizedBox(height: 6),
          Text(repository, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      SectionCard(
        title: strings.aboutPhilosophyTitle,
        children: [Text(strings.aboutPhilosophyBody)],
      ),
      SectionCard(
        title: strings.aboutPrivacyTitle,
        children: [Text(strings.aboutPrivacyBody)],
      ),
    ],
  );
}
