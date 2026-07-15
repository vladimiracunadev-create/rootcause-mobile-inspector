/// Historial local en JSON Lines — Dart puro sobre `dart:io`.
///
/// Cada captura es una línea JSON en un archivo del sandbox de la app,
/// con retención acotada. Sin SQLite ni plugins nativos extra: menos
/// superficie, misma evidencia. Nada sale del dispositivo.
library;

import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Fila resumida del historial para listar y comparar capturas.
class HistoryRow {
  const HistoryRow({
    required this.timestampMillis,
    required this.severity,
    required this.score,
    required this.memAvailablePct,
    required this.storageFreePct,
    required this.riskyApps,
  });

  final int timestampMillis;
  final Severity severity;
  final int score;
  final int memAvailablePct;
  final int storageFreePct;
  final int riskyApps;
}

class HistoryStore {
  HistoryStore(this.directoryPath, {this.maxRows = 500});

  final String directoryPath;
  final int maxRows;

  File get _file => File('$directoryPath/rootcause-history.jsonl');

  Future<void> append(String jsonLine) async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString('$jsonLine\n', mode: FileMode.append, flush: true);
    await _trim(file);
  }

  Future<void> _trim(File file) async {
    final lines = await _readLines(file);
    if (lines.length <= maxRows) return;
    final kept = lines.sublist(lines.length - maxRows);
    await file.writeAsString('${kept.join('\n')}\n', flush: true);
  }

  Future<List<String>> _readLines(File file) async {
    if (!await file.exists()) return const [];
    final content = await file.readAsString();
    return content.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  /// Últimas [limit] capturas, la más reciente primero. Una línea corrupta
  /// se ignora (evidencia parcial es mejor que crash).
  Future<List<HistoryRow>> recent({int limit = 60}) async {
    final lines = await _readLines(_file);
    final rows = <HistoryRow>[];
    for (final line in lines.reversed) {
      if (rows.length >= limit) break;
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        rows.add(_rowFromMap(map));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return rows;
  }

  HistoryRow _rowFromMap(Map<String, dynamic> map) {
    final verdict = map['verdict'] is Map ? map['verdict'] as Map : const {};
    final memory = map['memory'] is Map ? map['memory'] as Map : const {};
    final storage = map['storage'] is Map ? map['storage'] as Map : const {};
    final apps = map['apps'] is List ? map['apps'] as List : const [];

    int pct(num total, num part) => total > 0 ? (part * 100 ~/ total) : 0;
    num asNum(Object? v) => v is num ? v : 0;

    return HistoryRow(
      timestampMillis: asNum(map['timestampMillis']).toInt(),
      severity: severityFromName(
        verdict['severity'] is String
            ? verdict['severity'] as String
            : 'normal',
      ),
      score: asNum(verdict['score']).toInt(),
      memAvailablePct: pct(
        asNum(memory['totalBytes']),
        asNum(memory['availableBytes']),
      ),
      storageFreePct: pct(
        asNum(storage['totalBytes']),
        asNum(storage['freeBytes']),
      ),
      riskyApps: apps
          .whereType<Map>()
          .where(
            (a) => a['severity'] == 'warning' || a['severity'] == 'critical',
          )
          .length,
    );
  }
}
