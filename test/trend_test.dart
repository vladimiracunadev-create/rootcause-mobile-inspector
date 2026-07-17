import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/history_store.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';

import 'helpers.dart';

void main() {
  const engine = RuleEngine();
  const now = 1700000000000; // timestamp fijo de buildSnapshot()

  HistoryRow row({
    required int minutesAgo,
    required int memPct,
    int storagePct = 50,
  }) => HistoryRow(
    timestampMillis: now - minutesAgo * 60000,
    severity: Severity.normal,
    score: 0,
    memAvailablePct: memPct,
    storageFreePct: storagePct,
    riskyApps: 0,
  );

  /// Memoria actual al [pct] % de 8 GB, lejos de los umbrales absolutos.
  Snapshot snapshotWithMemPct(int pct) => buildSnapshot(
    memory: MemoryInfo(
      totalBytes: 8 * 1024 * 1024 * 1024,
      availableBytes: 8 * 1024 * 1024 * 1024 * pct ~/ 100,
      lowMemory: false,
    ),
  );

  group('RuleEngine — carga en ascenso (load-rising)', () {
    test('caída sostenida de memoria dispara el hallazgo con la serie', () {
      final history = [
        row(minutesAgo: 10, memPct: 30),
        row(minutesAgo: 60, memPct: 38),
        row(minutesAgo: 120, memPct: 45),
      ];
      final verdict = engine.evaluate(snapshotWithMemPct(22), history: history);
      final trend = verdict.findings.where((f) => f.id == 'load-rising');
      expect(trend, hasLength(1));
      expect(trend.first.severity, Severity.warning);
      expect(trend.first.args, ['memory', '45', '22']);
    });

    test('sin historial suficiente la regla se omite', () {
      final verdict = engine.evaluate(
        snapshotWithMemPct(22),
        history: [row(minutesAgo: 10, memPct: 45)],
      );
      expect(verdict.findings.where((f) => f.id == 'load-rising'), isEmpty);
    });

    test('una recuperación intermedia rompe la tendencia', () {
      final history = [
        row(minutesAgo: 10, memPct: 44), // rebota +14 sobre la anterior
        row(minutesAgo: 60, memPct: 30),
        row(minutesAgo: 120, memPct: 45),
      ];
      final verdict = engine.evaluate(snapshotWithMemPct(22), history: history);
      expect(verdict.findings.where((f) => f.id == 'load-rising'), isEmpty);
    });

    test('capturas fuera de la ventana de 6 h no cuentan', () {
      final history = [
        row(minutesAgo: 10, memPct: 30),
        row(minutesAgo: 60, memPct: 38),
        row(minutesAgo: 600, memPct: 45), // hace 10 h: fuera de ventana
      ];
      final verdict = engine.evaluate(snapshotWithMemPct(22), history: history);
      expect(verdict.findings.where((f) => f.id == 'load-rising'), isEmpty);
    });

    test('una caída pequeña (bajo trendDropPct) no alarma', () {
      final history = [
        row(minutesAgo: 10, memPct: 46),
        row(minutesAgo: 60, memPct: 48),
        row(minutesAgo: 120, memPct: 50),
      ];
      final verdict = engine.evaluate(snapshotWithMemPct(45), history: history);
      expect(verdict.findings.where((f) => f.id == 'load-rising'), isEmpty);
    });

    test('el disco también genera tendencia, independiente de la memoria', () {
      final history = [
        row(minutesAgo: 10, memPct: 50, storagePct: 20),
        row(minutesAgo: 60, memPct: 50, storagePct: 28),
        row(minutesAgo: 120, memPct: 50, storagePct: 35),
      ];
      final snapshot = buildSnapshot(
        storage: StorageInfo(
          totalBytes: 100 * 1024 * 1024 * 1024,
          freeBytes: 18 * 1024 * 1024 * 1024,
          appCacheBytes: 0,
        ),
      );
      final verdict = engine.evaluate(snapshot, history: history);
      final trend = verdict.findings.where((f) => f.id == 'load-rising');
      expect(trend, hasLength(1));
      expect(trend.first.args.first, 'storage');
    });
  });
}
