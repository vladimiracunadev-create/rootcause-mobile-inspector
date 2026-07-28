/// Informe forense compartible — PDF legible por humanos, generado en Dart
/// puro (sin dependencias de pub.dev; ver [PdfDocument]).
///
/// El equivalente móvil de los reportes de la edición Windows: veredicto,
/// hallazgos con evidencia, métricas, tendencia y estado de la cadena de
/// integridad. Se comparte por el share sheet del SISTEMA (la app sigue
/// sin permiso INTERNET).
library;

import 'dart:typed_data';

import '../core/history_store.dart';
import '../core/models.dart';
import '../meta.dart';
import 'pdf.dart';
import 'screens.dart' show formatBytes, formatTimestamp;
import 'strings.dart';

/// Construye el informe forense como bytes de un PDF listo para compartir.
Uint8List buildForensicReportPdf({
  required AppStrings strings,
  required Snapshot snapshot,
  required Verdict verdict,
  required List<HistoryRow> history,
  ChainReport? chain,
}) {
  final doc = PdfDocument();

  doc.title('${strings.reportTitle} — RootCause');
  doc.paragraph(
    '${strings.reportGenerated}: ${formatTimestamp(snapshot.timestampMillis)}',
  );
  doc.paragraph(
    '${strings.reportDevice}: ${snapshot.device.manufacturer} '
    '${snapshot.device.model} · ${snapshot.device.osVersion}'
    '${snapshot.device.vendorSkin.isNotEmpty ? ' · ${snapshot.device.vendorSkin}' : ''}',
  );
  doc.paragraph('${strings.devicePatch}: ${snapshot.device.securityPatch}');
  doc.paragraph('RootCause Mobile Inspector v${Meta.version}');

  final verdictLabel = switch (verdict.severity) {
    Severity.normal => strings.verdictNormal,
    Severity.warning => strings.verdictWarning,
    Severity.critical => strings.verdictCritical,
  };
  doc.heading(strings.reportVerdict);
  doc.paragraph(
    '$verdictLabel · ${strings.verdictScore(verdict.score)}',
    bold: true,
  );

  doc.heading(strings.reportFindings);
  if (verdict.findings.isEmpty) {
    doc.paragraph(strings.findingsNone);
  } else {
    for (final f in verdict.findings) {
      final severity = switch (f.severity) {
        Severity.normal => strings.severityNormal,
        Severity.warning => strings.severityWarning,
        Severity.critical => strings.severityCritical,
      };
      doc.bullet(
        '${strings.findingTitle(f)} [$severity] — ${strings.findingDetail(f)}',
      );
      final reco = strings.findingReco(f);
      if (reco.isNotEmpty) doc.paragraph('   ${strings.recommendation(reco)}');
    }
  }

  doc.heading(strings.reportMetrics);
  doc.bullet(
    '${strings.memTitle}: ${formatBytes(snapshot.memory.availableBytes)} '
    '${strings.reportAvailableOf(formatBytes(snapshot.memory.totalBytes))}',
  );
  doc.bullet(
    '${strings.storageTitle}: ${formatBytes(snapshot.storage.freeBytes)} '
    '${strings.reportFreeOf(formatBytes(snapshot.storage.totalBytes))}',
  );
  for (final v in snapshot.storage.volumes) {
    doc.bullet(
      '${v.label}: ${formatBytes(v.freeBytes)} / ${formatBytes(v.totalBytes)}'
      '${v.removable ? ' (${strings.volumeRemovable})' : ''}',
    );
  }
  doc.bullet(
    '${strings.batteryTitle}: ${snapshot.battery.levelPercent} % · '
    '${snapshot.battery.temperatureAvailable ? '${snapshot.battery.temperatureCelsius.toStringAsFixed(1)} °C' : strings.notAvailableOnPlatform}',
  );
  if (snapshot.device.appsAuditSupported) {
    final risky = snapshot.apps
        .where((a) => a.severity != Severity.normal)
        .length;
    doc.bullet(
      '${strings.appsTitle}: ${strings.reportAppsLine(snapshot.apps.length, risky)}',
    );
  }

  if (history.length >= 2) {
    doc.heading(strings.trendTitle);
    // Gráfico vectorial (como en la app): de la captura más antigua a la más
    // reciente. RAM disponible (azul) y disco libre (verde-azulado).
    final chrono = history.reversed.toList();
    if (chrono.length >= 3) {
      doc.chart(
        [
          [for (final r in chrono) r.memAvailablePct],
          [for (final r in chrono) r.storageFreePct],
        ],
        const [
          [0.1, 0.45, 0.85],
          [0.0, 0.6, 0.5],
        ],
      );
      doc.paragraph(
        '${strings.trendMemLegend}  ·  ${strings.trendStorageLegend}',
      );
    }
    doc.table(
      [
        strings.reportColSnapshot,
        'RAM %',
        '${strings.reportColStorage} %',
        strings.reportColScore,
      ],
      [
        for (final row in history.take(10))
          [
            formatTimestamp(row.timestampMillis),
            '${row.memAvailablePct}',
            '${row.storageFreePct}',
            '${row.score}',
          ],
      ],
    );
  }

  if (chain != null) {
    doc.heading(strings.reportIntegrityTitle);
    doc.paragraph(
      chain.intact
          ? strings.reportChainOk(chain.sealed, chain.total)
          : strings.reportChainTampered,
    );
  }

  doc.rule();
  doc.paragraph('${strings.reportFooter} ${Meta.repository}');

  return doc.build();
}
