/// Pantallas de la app — consumen el snapshot + veredicto y los textos
/// bilingües. Sin lógica de negocio: eso vive en lib/core/.
library;

import 'package:flutter/material.dart';

import '../core/config_store.dart';
import '../core/history_store.dart';
import '../core/models.dart';
import '../core/nearby.dart';
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
  const FindingCard({
    super.key,
    required this.finding,
    required this.strings,
    this.actionLabel,
    this.onAction,
  });

  final Finding finding;
  final AppStrings strings;

  /// Acción de intervención: abre la pantalla del sistema donde el usuario
  /// SÍ puede actuar. Solo se muestra donde existe una pantalla directa.
  final String? actionLabel;
  final VoidCallback? onAction;

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
            if (actionLabel != null && onAction != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(actionLabel!),
                  onPressed: onAction,
                ),
              ),
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

class AppsScreen extends StatelessWidget {
  const AppsScreen({
    super.key,
    required this.apps,
    required this.auditSupported,
    required this.strings,
    this.onOpenApp,
  });

  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;

  /// Abre la ficha de sistema de la app (ahí se desinstala o se revocan
  /// permisos — la intervención real que el SO sí permite).
  final void Function(String packageName)? onOpenApp;

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
                  if (onOpenApp != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(strings.actionAppDetails),
                        onPressed: () => onOpenApp!(app.packageName),
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
    this.onClearCache,
  });

  final StorageInfo storage;
  final AppStrings strings;
  final VoidCallback? onClearCache;

  @override
  Widget build(BuildContext context) {
    final used = storage.totalBytes - storage.freeBytes;
    return ListView(
      children: [
        SectionCard(
          title: '${strings.storageTitle} — ${strings.volumeInternal}',
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
        // Volúmenes adicionales (SD/USB): solo si existen. Un teléfono sin
        // tarjeta es el caso normal, no un estado de error.
        if (storage.volumes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              strings.volumesNone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...storage.volumes.map(
            (v) => SectionCard(
              title: v.removable
                  ? '${v.label} (${strings.volumeRemovable})'
                  : v.label,
              children: [
                LinearProgressIndicator(
                  value: (1.0 - v.freeRatio).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 8),
                InfoRow(
                  label: strings.storageFree,
                  value: formatBytes(v.freeBytes),
                ),
                InfoRow(
                  label: strings.storageTotal,
                  value: formatBytes(v.totalBytes),
                ),
              ],
            ),
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
            if (onClearCache != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.cleaning_services, size: 16),
                  label: Text(strings.cacheClear),
                  onPressed: onClearCache,
                ),
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
          if (device.vendorSkin.isNotEmpty)
            InfoRow(label: strings.deviceSkin, value: device.vendorSkin),
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

/// Gráfico de tendencia sin dependencias: dos series porcentuales (RAM
/// disponible y disco libre) sobre las capturas del historial, de la más
/// antigua a la más reciente.
class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.memSeries,
    required this.storageSeries,
    required this.memColor,
    required this.storageColor,
    required this.gridColor,
  });

  final List<int> memSeries;
  final List<int> storageSeries;
  final Color memColor;
  final Color storageColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final pct in const [0, 50, 100]) {
      final y = size.height * (1 - pct / 100);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _polyline(canvas, size, memSeries, memColor);
    _polyline(canvas, size, storageSeries, storageColor);
  }

  void _polyline(Canvas canvas, Size size, List<int> series, Color color) {
    if (series.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final step = size.width / (series.length - 1);
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final x = step * i;
      final y = size.height * (1 - series[i].clamp(0, 100) / 100);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.memSeries != memSeries || old.storageSeries != storageSeries;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.history,
    required this.strings,
  });

  final List<HistoryRow> history;
  final AppStrings strings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Selección A/B por timestamp (estable aunque llegue una captura nueva).
  int? _selA;
  int? _selB;

  void _toggle(int timestamp) {
    setState(() {
      if (_selA == timestamp) {
        _selA = _selB;
        _selB = null;
      } else if (_selB == timestamp) {
        _selB = null;
      } else if (_selA == null) {
        _selA = timestamp;
      } else if (_selB == null) {
        _selB = timestamp;
      } else {
        _selA = timestamp;
        _selB = null;
      }
    });
  }

  HistoryRow? _rowFor(int? timestamp) {
    if (timestamp == null) return null;
    for (final row in widget.history) {
      if (row.timestampMillis == timestamp) return row;
    }
    return null;
  }

  String _delta(int value) => value >= 0 ? '+$value' : '$value';

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final history = widget.history;
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(strings.historyEmpty),
      );
    }

    final theme = Theme.of(context);
    final memColor = theme.colorScheme.primary;
    final storageColor = theme.colorScheme.tertiary;
    final chronological = history.reversed.toList();

    final a = _rowFor(_selA);
    final b = _rowFor(_selB);
    // A → B siempre en orden temporal, elija como elija el usuario.
    final from = a != null && b != null
        ? (a.timestampMillis <= b.timestampMillis ? a : b)
        : null;
    final to = a != null && b != null
        ? (a.timestampMillis <= b.timestampMillis ? b : a)
        : null;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            strings.historyTitle(history.length),
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (history.length >= 3)
          SectionCard(
            title: strings.trendTitle,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TrendPainter(
                    memSeries: [
                      for (final r in chronological) r.memAvailablePct,
                    ],
                    storageSeries: [
                      for (final r in chronological) r.storageFreePct,
                    ],
                    memColor: memColor,
                    storageColor: storageColor,
                    gridColor: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendDot(memColor, strings.trendMemLegend),
                  const SizedBox(width: 16),
                  _legendDot(storageColor, strings.trendStorageLegend),
                ],
              ),
            ],
          ),
        if (from != null && to != null)
          SectionCard(
            title: strings.compareTitle,
            children: [
              Text(
                '${formatTimestamp(from.timestampMillis)} → '
                '${formatTimestamp(to.timestampMillis)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              InfoRow(
                label: strings.compareMem,
                value:
                    '${from.memAvailablePct} % → ${to.memAvailablePct} % '
                    '(${_delta(to.memAvailablePct - from.memAvailablePct)})',
              ),
              InfoRow(
                label: strings.compareStorage,
                value:
                    '${from.storageFreePct} % → ${to.storageFreePct} % '
                    '(${_delta(to.storageFreePct - from.storageFreePct)})',
              ),
              InfoRow(
                label: strings.compareScore,
                value:
                    '${from.score} → ${to.score} '
                    '(${_delta(to.score - from.score)})',
              ),
              InfoRow(
                label: strings.compareRisky,
                value:
                    '${from.riskyApps} → ${to.riskyApps} '
                    '(${_delta(to.riskyApps - from.riskyApps)})',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(strings.compareClear),
                  onPressed: () => setState(() {
                    _selA = null;
                    _selB = null;
                  }),
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(strings.compareHint, style: theme.textTheme.bodySmall),
          ),
        ...history.map((row) {
          final selected =
              row.timestampMillis == _selA || row.timestampMillis == _selB;
          return Material(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _toggle(row.timestampMillis),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
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
                          style: theme.textTheme.bodySmall,
                        ),
                        if (selected) ...[
                          const Spacer(),
                          Icon(
                            Icons.compare_arrows,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      strings.historyRow(
                        row.memAvailablePct,
                        row.storageFreePct,
                        row.riskyApps,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Estado del escaneo BLE que la pantalla de Cercanía comunica sin fingir:
/// denegado y no-soportado son estados visibles, no silencios.
enum NearbyStatus { idle, scanning, denied, unsupported }

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({
    super.key,
    required this.session,
    required this.status,
    required this.strings,
    required this.onScan,
  });

  final NearbySession session;
  final NearbyStatus status;
  final AppStrings strings;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final devices = session.devices;
    final persistent = session.persistentCount;
    return ListView(
      children: [
        SectionCard(
          title: strings.nearbyTitle,
          children: [
            Text(strings.nearbyIntro),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: status == NearbyStatus.scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching, size: 18),
                label: Text(
                  status == NearbyStatus.scanning
                      ? strings.nearbyScanning
                      : strings.nearbyScan(15),
                ),
                onPressed: status == NearbyStatus.scanning ? null : onScan,
              ),
            ),
            if (status == NearbyStatus.denied) ...[
              const SizedBox(height: 8),
              Text(strings.nearbyPermissionDenied),
            ],
            if (status == NearbyStatus.unsupported) ...[
              const SizedBox(height: 8),
              Text(strings.nearbyUnsupported),
            ],
          ],
        ),
        if (session.scanCount > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              strings.nearbySummary(devices.length, session.scanCount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (persistent > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                strings.nearbyPersistentNote(persistent),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ...devices.map(
            (d) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  d.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (session.isPersistent(d)) ...[
                                const SizedBox(width: 8),
                                Text(
                                  strings.nearbyPersistent,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${d.address} · ${strings.nearbySeen(d.seenScans)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text('${d.rssi} dBm'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.nearbyHonestyNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.config,
    required this.strings,
    required this.onChanged,
  });

  final AppConfig config;
  final AppStrings strings;
  final ValueChanged<AppConfig> onChanged;

  /// Fila de umbral con paso de ±1 dentro de [min, max].
  Widget _stepper(
    BuildContext context, {
    required String label,
    required int value,
    required String unit,
    required int min,
    required int max,
    required ValueChanged<int> onValue,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onValue(value - 1) : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value $unit',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onValue(value + 1) : null,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = config;
    return ListView(
      children: [
        SectionCard(
          title: strings.settingsCaptureTitle,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(strings.settingsInterval)),
                DropdownButton<int>(
                  value: c.autoRefreshMinutes,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(strings.settingsIntervalOff),
                    ),
                    for (final m in const [1, 5, 15])
                      DropdownMenuItem(
                        value: m,
                        child: Text(strings.settingsIntervalMinutes(m)),
                      ),
                  ],
                  onChanged: (v) => v == null
                      ? null
                      : onChanged(c.copyWith(autoRefreshMinutes: v)),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsBackground),
              value: c.backgroundCapture,
              onChanged: (v) => onChanged(c.copyWith(backgroundCapture: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsChargingOnly),
              value: c.backgroundChargingOnly,
              onChanged: c.backgroundCapture
                  ? (v) => onChanged(c.copyWith(backgroundChargingOnly: v))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsNotifyCritical),
              value: c.notifyCritical,
              onChanged: (v) => onChanged(c.copyWith(notifyCritical: v)),
            ),
          ],
        ),
        SectionCard(
          title: strings.settingsThresholdsTitle,
          children: [
            _stepper(
              context,
              label: strings.thresholdMemWarning,
              value: c.memoryWarningPct,
              unit: '%',
              min: c.memoryCriticalPct + 1,
              max: 50,
              onValue: (v) => onChanged(c.copyWith(memoryWarningPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdMemCritical,
              value: c.memoryCriticalPct,
              unit: '%',
              min: 1,
              max: c.memoryWarningPct - 1,
              onValue: (v) => onChanged(c.copyWith(memoryCriticalPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdStorageWarning,
              value: c.storageWarningPct,
              unit: '%',
              min: c.storageCriticalPct + 1,
              max: 50,
              onValue: (v) => onChanged(c.copyWith(storageWarningPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdStorageCritical,
              value: c.storageCriticalPct,
              unit: '%',
              min: 1,
              max: c.storageWarningPct - 1,
              onValue: (v) => onChanged(c.copyWith(storageCriticalPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdBatteryWarning,
              value: c.batteryTempWarningCelsius,
              unit: '°C',
              min: 30,
              max: c.batteryTempCriticalCelsius - 1,
              onValue: (v) =>
                  onChanged(c.copyWith(batteryTempWarningCelsius: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdBatteryCritical,
              value: c.batteryTempCriticalCelsius,
              unit: '°C',
              min: c.batteryTempWarningCelsius + 1,
              max: 60,
              onValue: (v) =>
                  onChanged(c.copyWith(batteryTempCriticalCelsius: v)),
            ),
            const SizedBox(height: 4),
            Text(
              strings.settingsThresholdsNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: Text(strings.settingsRestoreDefaults),
                onPressed: () => onChanged(
                  AppConfig(
                    spanish: c.spanish,
                    autoRefreshMinutes: c.autoRefreshMinutes,
                    backgroundCapture: c.backgroundCapture,
                    backgroundChargingOnly: c.backgroundChargingOnly,
                  ),
                ),
              ),
            ),
          ],
        ),
        SectionCard(
          title: strings.settingsLanguageTitle,
          children: [
            Row(
              children: [
                for (final (label, spanish) in const [
                  ('Español', true),
                  ('English', false),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: c.spanish == spanish,
                      onSelected: (_) =>
                          onChanged(c.copyWith(spanish: spanish)),
                    ),
                  ),
              ],
            ),
          ],
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
