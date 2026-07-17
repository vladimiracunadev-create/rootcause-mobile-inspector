/// Historial local en JSON Lines — Dart puro sobre `dart:io`.
///
/// Cada captura es una línea JSON en un archivo del sandbox de la app,
/// con retención acotada. Sin SQLite ni plugins nativos extra: menos
/// superficie, misma evidencia. Nada sale del dispositivo.
library;

import 'dart:convert';
import 'dart:io';

import 'models.dart';
import 'sha256.dart';

/// Estado de la cadena de integridad del historial.
class ChainReport {
  const ChainReport({
    required this.total,
    required this.sealed,
    required this.intact,
  });

  /// Capturas totales en el archivo.
  final int total;

  /// Capturas selladas (con hash); las anteriores a v0.5.0 no lo tienen.
  final int sealed;

  /// `true` si todos los sellos verifican y los eslabones encadenan.
  final bool intact;
}

/// Fila resumida del historial para listar y comparar capturas.
class HistoryRow {
  const HistoryRow({
    required this.timestampMillis,
    required this.severity,
    required this.score,
    required this.memAvailablePct,
    required this.storageFreePct,
    required this.riskyApps,
    this.batteryTempC = -1,
  });

  final int timestampMillis;
  final Severity severity;
  final int score;
  final int memAvailablePct;
  final int storageFreePct;
  final int riskyApps;

  /// Temperatura de batería (°C redondeados); -1 si la plataforma no la
  /// expone (iOS) — la serie del gráfico la omite.
  final int batteryTempC;
}

class HistoryStore {
  HistoryStore(this.directoryPath, {this.maxRows = 500});

  final String directoryPath;
  final int maxRows;

  File get _file => File('$directoryPath/rootcause-history.jsonl');

  /// Sella y anexa una captura: `prevHash` enlaza con la anterior y
  /// `hash` = SHA-256 del contenido — evidencia manipulable se vuelve
  /// evidencia VERIFICABLE. Tras el recorte de retención la cadena sigue
  /// siendo válida dentro de la ventana retenida.
  Future<void> append(Map<String, Object?> capture) async {
    final file = _file;
    await file.parent.create(recursive: true);

    var prevHash = '';
    final lines = await _readLines(file);
    if (lines.isNotEmpty) {
      try {
        final last = jsonDecode(lines.last);
        if (last is Map && last['hash'] is String) {
          prevHash = last['hash'] as String;
        }
      } on FormatException {
        // Última línea corrupta: la cadena arranca de nuevo aquí.
      }
    }

    final sealed = Map<String, Object?>.from(capture)..remove('hash');
    sealed['prevHash'] = prevHash;
    sealed['hash'] = _sealHash(sealed);
    await file.writeAsString(
      '${jsonEncode(sealed)}\n',
      mode: FileMode.append,
      flush: true,
    );
    await _trim(file);
  }

  /// Hash del contenido sellado (todo el mapa salvo `hash`, incluido
  /// `prevHash`): el orden de claves de jsonEncode es estable porque el
  /// mapa se construye siempre por el mismo código.
  static String _sealHash(Map<String, Object?> withoutHash) =>
      sha256Hex(jsonEncode(withoutHash));

  /// Verifica la cadena completa. Las líneas anteriores a v0.5.0 (sin
  /// `hash`) cuentan como no selladas; a partir del primer sello, cada
  /// eslabón debe verificar y encadenar.
  Future<ChainReport> verifyChain() async {
    final lines = await _readLines(_file);
    var sealed = 0;
    var intact = true;
    String? expectedPrev;
    for (final line in lines) {
      Object? decoded;
      try {
        decoded = jsonDecode(line);
      } on FormatException {
        intact = false;
        continue;
      }
      if (decoded is! Map<String, dynamic>) continue;
      final hash = decoded['hash'];
      if (hash is! String) {
        // Captura legado sin sello: no rompe, pero tampoco cuenta.
        expectedPrev = null;
        continue;
      }
      sealed++;
      final copy = Map<String, Object?>.from(decoded)..remove('hash');
      if (_sealHash(copy) != hash) intact = false;
      if (expectedPrev != null && decoded['prevHash'] != expectedPrev) {
        intact = false;
      }
      expectedPrev = hash;
    }
    return ChainReport(total: lines.length, sealed: sealed, intact: intact);
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
    final battery = map['battery'] is Map ? map['battery'] as Map : const {};
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
      batteryTempC: battery['temperatureAvailable'] == true
          ? asNum(battery['temperatureCelsius']).round()
          : -1,
    );
  }
}
