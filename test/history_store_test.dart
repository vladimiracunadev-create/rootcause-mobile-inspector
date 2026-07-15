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

  String line({int ts = 1700000000000}) {
    final snapshot = buildSnapshot();
    final verdict = engine.evaluate(snapshot);
    final raw = SnapshotJson.toJsonLine(snapshot, verdict);
    return raw.replaceFirst(
      '"timestampMillis":1700000000000',
      '"timestampMillis":$ts',
    );
  }

  test('append + recent devuelve la captura más reciente primero', () async {
    final store = HistoryStore(tempDir.path);
    await store.append(line(ts: 1));
    await store.append(line(ts: 2));
    await store.append(line(ts: 3));

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
      await store.append(line(ts: i));
    }
    final rows = await store.recent();
    expect(rows.length, 5);
    expect(rows.first.timestampMillis, 8);
    expect(rows.last.timestampMillis, 4);
  });

  test('una línea corrupta se ignora sin perder el resto', () async {
    final store = HistoryStore(tempDir.path);
    await store.append(line(ts: 1));
    await store.append('{esto-no-es-json');
    await store.append(line(ts: 2));

    final rows = await store.recent();
    expect(rows.length, 2);
    expect(rows.map((r) => r.timestampMillis), [2, 1]);
  });

  test('recent con historial vacío devuelve lista vacía', () async {
    final store = HistoryStore(tempDir.path);
    expect(await store.recent(), isEmpty);
  });
}
