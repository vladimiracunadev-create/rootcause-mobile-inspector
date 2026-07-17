import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/history_store.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';
import 'package:rootcause_mobile_inspector/core/snapshot_json.dart';

import 'helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rootcause-test-');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const engine = RuleEngine();

  Map<String, Object?> capture({int ts = 1700000000000}) {
    final snapshot = buildSnapshot();
    final verdict = engine.evaluate(snapshot);
    final map = SnapshotJson.toMap(snapshot, verdict);
    map['timestampMillis'] = ts;
    return map;
  }

  test('append + recent devuelve la captura más reciente primero', () async {
    final store = HistoryStore(tempDir.path);
    await store.append(capture(ts: 1));
    await store.append(capture(ts: 2));
    await store.append(capture(ts: 3));

    final rows = await store.recent();
    expect(rows.length, 3);
    expect(rows.first.timestampMillis, 3);
    expect(rows.last.timestampMillis, 1);
    expect(rows.first.severity, Severity.normal);
    expect(rows.first.memAvailablePct, 50);
  });

  test('la retención recorta a maxRows conservando lo más nuevo', () async {
    final store = HistoryStore(tempDir.path, maxRows: 5);
    for (var i = 1; i <= 8; i++) {
      await store.append(capture(ts: i));
    }
    final rows = await store.recent();
    expect(rows.length, 5);
    expect(rows.first.timestampMillis, 8);
    expect(rows.last.timestampMillis, 4);
  });

  test('una línea corrupta se ignora sin perder el resto', () async {
    final store = HistoryStore(tempDir.path);
    await store.append(capture(ts: 1));
    await File(
      '${tempDir.path}/rootcause-history.jsonl',
    ).writeAsString('{esto-no-es-json\n', mode: FileMode.append);
    await store.append(capture(ts: 2));

    final rows = await store.recent();
    expect(rows.length, 2);
    expect(rows.map((r) => r.timestampMillis), [2, 1]);
  });

  test('recent con historial vacío devuelve lista vacía', () async {
    final store = HistoryStore(tempDir.path);
    expect(await store.recent(), isEmpty);
  });

  group('cadena de integridad (v0.5.0)', () {
    test('cada captura queda sellada y la cadena verifica', () async {
      final store = HistoryStore(tempDir.path);
      await store.append(capture(ts: 1));
      await store.append(capture(ts: 2));
      await store.append(capture(ts: 3));

      final report = await store.verifyChain();
      expect(report.total, 3);
      expect(report.sealed, 3);
      expect(report.intact, isTrue);
    });

    test('editar una captura a mano ROMPE la cadena (evidencia)', () async {
      final store = HistoryStore(tempDir.path);
      await store.append(capture(ts: 1));
      await store.append(capture(ts: 2));

      final file = File('${tempDir.path}/rootcause-history.jsonl');
      final lines = (await file.readAsString()).trim().split('\n');
      final tampered = jsonDecode(lines.first) as Map<String, dynamic>
        ..['timestampMillis'] = 999;
      lines[0] = jsonEncode(tampered);
      await file.writeAsString('${lines.join('\n')}\n');

      final report = await store.verifyChain();
      expect(report.intact, isFalse);
    });

    test('la cadena sigue válida tras el recorte de retención', () async {
      final store = HistoryStore(tempDir.path, maxRows: 3);
      for (var i = 1; i <= 6; i++) {
        await store.append(capture(ts: i));
      }
      final report = await store.verifyChain();
      expect(report.total, 3);
      expect(report.intact, isTrue);
    });

    test('capturas legado (sin sello) no rompen la verificación', () async {
      final file = File('${tempDir.path}/rootcause-history.jsonl');
      await file.create(recursive: true);
      await file.writeAsString(
        '${jsonEncode(capture(ts: 1))}\n', // legado: sin hash
      );
      final store = HistoryStore(tempDir.path);
      await store.append(capture(ts: 2));

      final report = await store.verifyChain();
      expect(report.total, 2);
      expect(report.sealed, 1);
      expect(report.intact, isTrue);
    });
  });
}
