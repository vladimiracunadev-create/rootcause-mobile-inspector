/// Piezas de UI compartidas por todas las pantallas: formateadores y los
/// widgets que componen el vocabulario visual del sensor (semáforo, tarjeta
/// de hallazgo, filas de datos).
library;

import 'package:flutter/material.dart';

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
      child: Semantics(
        label: label,
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
