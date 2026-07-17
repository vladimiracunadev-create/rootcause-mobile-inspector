/// Informe forense compartible — Markdown legible por humanos.
///
/// El equivalente móvil de los reportes de la edición Windows: veredicto,
/// hallazgos con evidencia, métricas, tendencia y estado de la cadena de
/// integridad. Se comparte por el share sheet del SISTEMA (la app sigue
/// sin permiso INTERNET).
library;

import '../core/history_store.dart';
import '../core/models.dart';
import '../meta.dart';
import 'screens.dart' show formatBytes, formatTimestamp;
import 'strings.dart';

String buildForensicReport({
  required AppStrings strings,
  required Snapshot snapshot,
  required Verdict verdict,
  required List<HistoryRow> history,
  ChainReport? chain,
}) {
  final b = StringBuffer();
  final es = strings.spanish;
  String t(String a, String bTxt) => es ? a : bTxt;

  b.writeln('# ${t('Informe forense', 'Forensic report')} — RootCause');
  b.writeln();
  b.writeln(
    '- ${t('Generado', 'Generated')}: '
    '${formatTimestamp(snapshot.timestampMillis)}',
  );
  b.writeln(
    '- ${t('Equipo', 'Device')}: ${snapshot.device.manufacturer} '
    '${snapshot.device.model} · ${snapshot.device.osVersion}'
    '${snapshot.device.vendorSkin.isNotEmpty ? ' · ${snapshot.device.vendorSkin}' : ''}',
  );
  b.writeln(
    '- ${t('Parche de seguridad', 'Security patch')}: '
    '${snapshot.device.securityPatch}',
  );
  b.writeln('- RootCause Mobile Inspector v${Meta.version}');
  b.writeln();

  final verdictLabel = switch (verdict.severity) {
    Severity.normal => strings.verdictNormal,
    Severity.warning => strings.verdictWarning,
    Severity.critical => strings.verdictCritical,
  };
  b.writeln('## ${t('Veredicto', 'Verdict')}');
  b.writeln();
  b.writeln('**$verdictLabel** · ${strings.verdictScore(verdict.score)}');
  b.writeln();

  b.writeln('## ${t('Hallazgos', 'Findings')}');
  b.writeln();
  if (verdict.findings.isEmpty) {
    b.writeln(strings.findingsNone);
  } else {
    for (final f in verdict.findings) {
      final severity = switch (f.severity) {
        Severity.normal => strings.severityNormal,
        Severity.warning => strings.severityWarning,
        Severity.critical => strings.severityCritical,
      };
      b.writeln(
        '- **${strings.findingTitle(f)}** [$severity] — '
        '${strings.findingDetail(f)} (`${f.id}`)',
      );
    }
  }
  b.writeln();

  b.writeln('## ${t('Métricas', 'Metrics')}');
  b.writeln();
  b.writeln(
    '- ${strings.memTitle}: '
    '${formatBytes(snapshot.memory.availableBytes)} '
    '${t('disponibles de', 'available of')} '
    '${formatBytes(snapshot.memory.totalBytes)}',
  );
  b.writeln(
    '- ${strings.storageTitle}: '
    '${formatBytes(snapshot.storage.freeBytes)} '
    '${t('libres de', 'free of')} '
    '${formatBytes(snapshot.storage.totalBytes)}',
  );
  for (final v in snapshot.storage.volumes) {
    b.writeln(
      '- ${v.label}: ${formatBytes(v.freeBytes)} / '
      '${formatBytes(v.totalBytes)}'
      '${v.removable ? ' (${strings.volumeRemovable})' : ''}',
    );
  }
  b.writeln(
    '- ${strings.batteryTitle}: ${snapshot.battery.levelPercent} % · '
    '${snapshot.battery.temperatureAvailable ? '${snapshot.battery.temperatureCelsius.toStringAsFixed(1)} °C' : strings.notAvailableOnPlatform}',
  );
  if (snapshot.device.appsAuditSupported) {
    final risky = snapshot.apps
        .where((a) => a.severity != Severity.normal)
        .length;
    b.writeln(
      '- ${strings.appsTitle}: ${snapshot.apps.length} '
      '${t('apps de usuario', 'user apps')}, $risky '
      '${t('con superficie riesgosa', 'with risky surface')}',
    );
  }
  b.writeln();

  if (history.length >= 2) {
    b.writeln('## ${strings.trendTitle}');
    b.writeln();
    b.writeln(
      '| ${t('Captura', 'Snapshot')} | RAM % | '
      '${t('Disco', 'Storage')} % | ${t('Puntaje', 'Score')} |',
    );
    b.writeln('|---|---|---|---|');
    for (final row in history.take(10)) {
      b.writeln(
        '| ${formatTimestamp(row.timestampMillis)} | '
        '${row.memAvailablePct} | ${row.storageFreePct} | ${row.score} |',
      );
    }
    b.writeln();
  }

  if (chain != null) {
    b.writeln('## ${t('Integridad de la evidencia', 'Evidence integrity')}');
    b.writeln();
    b.writeln(
      chain.intact
          ? t(
              'Cadena de hashes VERIFICADA: ${chain.sealed} de ${chain.total} capturas selladas (SHA-256 encadenado).',
              'Hash chain VERIFIED: ${chain.sealed} of ${chain.total} snapshots sealed (chained SHA-256).',
            )
          : t(
              'ATENCIÓN: la cadena de hashes NO verifica — el historial pudo ser alterado.',
              'WARNING: the hash chain does NOT verify — the history may have been tampered with.',
            ),
    );
    b.writeln();
  }

  b.writeln('---');
  b.writeln(
    t(
      'Generado localmente por RootCause Mobile Inspector (sin permiso INTERNET: nada salió del dispositivo hasta que su dueño compartió este archivo). ${Meta.repository}',
      'Generated locally by RootCause Mobile Inspector (no INTERNET permission: nothing left the device until its owner shared this file). ${Meta.repository}',
    ),
  );
  return b.toString();
}
