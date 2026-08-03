/// Tests de v0.8.0 — comportamiento observado y correlación temporal.
///
/// Las dos reglas nuevas comparten una exigencia: pueden señalar a una app
/// concreta, así que la prueba importante no es que disparen, sino que NO
/// disparen cuando la evidencia no da para tanto.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/baseline_store.dart';
import 'package:rootcause_mobile_inspector/core/history_store.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';
import 'package:rootcause_mobile_inspector/core/usage_baseline.dart';
import 'package:rootcause_mobile_inspector/ui/strings.dart';

import 'helpers.dart';

const _mb = 1024 * 1024;

void main() {
  const engine = RuleEngine();
  const now = 1700000000000; // timestamp fijo de buildSnapshot()

  AppUsageAnomaly anomaly({
    String label = 'Notas',
    List<String> specialFlags = const [],
    int baseline = 10 * _mb,
    int current = 500 * _mb,
  }) => AppUsageAnomaly(
    app: buildAppRisk(label: label, specialFlags: specialFlags),
    metric: UsageMetric.data,
    baselineValue: baseline,
    currentValue: current,
  );

  group('RuleEngine — app-usage-anomaly', () {
    test('sin anomalías no hay hallazgo', () {
      final verdict = engine.evaluate(buildSnapshot());
      expect(
        verdict.findings.where((f) => f.id == 'app-usage-anomaly'),
        isEmpty,
      );
    });

    test('anomalía sin capacidad activa es advertencia', () {
      final verdict = engine.evaluate(
        buildSnapshot(),
        usageAnomalies: [anomaly()],
      );
      final f = verdict.findings.singleWhere(
        (f) => f.id == 'app-usage-anomaly',
      );
      expect(f.severity, Severity.warning);
      expect(f.args[0], '1');
      expect(f.args[1], contains('Notas'));
      expect(f.args[2], '0');
    });

    test('consumo disparado + capacidad de espionaje activa es CRÍTICO', () {
      final verdict = engine.evaluate(
        buildSnapshot(),
        usageAnomalies: [
          anomaly(
            label: 'Teclado',
            specialFlags: const ['accessibility-service'],
          ),
        ],
      );
      final f = verdict.findings.singleWhere(
        (f) => f.id == 'app-usage-anomaly',
      );
      expect(f.severity, Severity.critical);
      expect(f.args[2], '1');
      expect(verdict.severity, Severity.critical);
    });

    test('la notación del múltiplo es neutral al idioma', () {
      final verdict = engine.evaluate(
        buildSnapshot(),
        usageAnomalies: [
          anomaly(baseline: 10 * _mb, current: 70 * _mb),
          anomaly(label: 'Silenciosa', baseline: 0, current: 300 * _mb),
        ],
      );
      final f = verdict.findings.singleWhere(
        (f) => f.id == 'app-usage-anomaly',
      );
      expect(f.args[1], contains('(×7)'));
      // Línea base cero: no hay múltiplo, se declara como tal.
      expect(f.args[1], contains('Silenciosa (×∞)'));
    });
  });

  group('RuleEngine — correlación temporal (load-rising-suspect)', () {
    HistoryRow row({required int minutesAgo, required int memPct}) =>
        HistoryRow(
          timestampMillis: now - minutesAgo * 60000,
          severity: Severity.normal,
          score: 0,
          memAvailablePct: memPct,
          storageFreePct: 50,
          riskyApps: 0,
        );

    Snapshot decliningSnapshot(List<AppRisk> apps) => buildSnapshot(
      memory: const MemoryInfo(
        totalBytes: 8 * 1024 * 1024 * 1024,
        availableBytes: 8 * 1024 * 1024 * 1024 * 22 ~/ 100,
        lowMemory: false,
      ),
      apps: apps,
    );

    final declining = [
      row(minutesAgo: 10, memPct: 30),
      row(minutesAgo: 60, memPct: 38),
      row(minutesAgo: 120, memPct: 45),
    ];

    test('sin deterioro sostenido no se señala a ninguna app', () {
      // Mismas instalaciones recientes, pero memoria estable.
      final verdict = engine.evaluate(
        buildSnapshot(apps: [buildAppRisk(packageName: 'com.nueva')]),
        recentInstalls: const {'com.nueva'},
      );
      expect(
        verdict.findings.where((f) => f.id == 'load-rising-suspect'),
        isEmpty,
      );
    });

    test('con deterioro pero sin instalaciones recientes, tampoco', () {
      final verdict = engine.evaluate(
        decliningSnapshot([buildAppRisk(packageName: 'com.vieja')]),
        history: declining,
      );
      expect(verdict.findings.any((f) => f.id == 'load-rising'), isTrue);
      expect(
        verdict.findings.where((f) => f.id == 'load-rising-suspect'),
        isEmpty,
      );
    });

    test('deterioro + instalación en la ventana nombra la coincidencia', () {
      final verdict = engine.evaluate(
        decliningSnapshot([
          buildAppRisk(packageName: 'com.nueva', label: 'Linterna Pro'),
          buildAppRisk(packageName: 'com.vieja', label: 'Correo'),
        ]),
        history: declining,
        recentInstalls: const {'com.nueva'},
      );
      final f = verdict.findings.singleWhere(
        (f) => f.id == 'load-rising-suspect',
      );
      expect(f.severity, Severity.warning);
      expect(f.args, ['1', 'Linterna Pro']);
    });

    test('el texto deja claro que coincidir no es causar', () {
      const f = Finding(
        id: 'load-rising-suspect',
        severity: Severity.warning,
        args: ['1', 'Linterna Pro'],
      );
      for (final lang in AppLang.values) {
        final detail = AppStrings(lang).findingDetail(f);
        expect(detail, contains('Linterna Pro'));
        expect(detail.length, greaterThan(40));
        expect(AppStrings(lang).findingTitle(f), isNot(f.id));
        expect(AppStrings(lang).findingReco(f), isNotEmpty);
      }
    });
  });

  group('los dos hallazgos nuevos están traducidos a los 5 idiomas', () {
    test('title, detail y reco existen y no caen al id', () {
      const findings = [
        Finding(
          id: 'app-usage-anomaly',
          severity: Severity.critical,
          args: ['2', 'Notas (×7)', '1'],
        ),
        Finding(
          id: 'load-rising-suspect',
          severity: Severity.warning,
          args: ['1', 'Linterna Pro'],
        ),
      ];
      for (final lang in AppLang.values) {
        final s = AppStrings(lang);
        for (final f in findings) {
          expect(
            s.findingTitle(f),
            isNot(f.id),
            reason: '${lang.name}/${f.id}',
          );
          expect(s.findingDetail(f), isNotEmpty);
          expect(s.findingReco(f), isNotEmpty);
        }
      }
    });
  });

  group('BaselineStore.installedWithin', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('rootcause-baseline-v080');
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('la inicialización NO cuenta como instalación observada', () async {
      final store = BaselineStore(dir.path);
      // Primera captura: se registra toda la biblioteca de golpe.
      await store.diffAndUpdate(
        [
          buildAppRisk(packageName: 'com.a'),
          buildAppRisk(packageName: 'com.b'),
        ],
        nowMillis: now,
        auditSupported: true,
      );

      // Aunque sus fechas sean "de ahora mismo", no sabemos cuándo se
      // instalaron: señalarlas sería inventar.
      expect(
        await store.installedWithin(const Duration(hours: 12), nowMillis: now),
        isEmpty,
      );
    });

    test('una app que llega después sí se observa', () async {
      final store = BaselineStore(dir.path);
      await store.diffAndUpdate(
        [buildAppRisk(packageName: 'com.a')],
        nowMillis: now,
        auditSupported: true,
      );
      await store.diffAndUpdate(
        [
          buildAppRisk(packageName: 'com.a'),
          buildAppRisk(packageName: 'com.nueva'),
        ],
        nowMillis: now + 3600 * 1000,
        auditSupported: true,
      );

      expect(
        await store.installedWithin(
          const Duration(hours: 12),
          nowMillis: now + 3600 * 1000,
        ),
        {'com.nueva'},
      );
    });

    test('fuera de la ventana deja de señalarse', () async {
      final store = BaselineStore(dir.path);
      await store.diffAndUpdate(
        [buildAppRisk(packageName: 'com.a')],
        nowMillis: now,
        auditSupported: true,
      );
      const installedAt = now + 3600 * 1000;
      await store.diffAndUpdate(
        [
          buildAppRisk(packageName: 'com.a'),
          buildAppRisk(packageName: 'com.nueva'),
        ],
        nowMillis: installedAt,
        auditSupported: true,
      );

      expect(
        await store.installedWithin(
          const Duration(hours: 12),
          nowMillis: installedAt + 13 * 3600 * 1000,
        ),
        isEmpty,
      );
    });

    test('un baseline previo a v0.8.0 (sin marca) no rompe', () async {
      await File('${dir.path}/rootcause-apps-baseline.json').writeAsString(
        jsonEncode({
          'packages': {
            'com.legacy': {
              'firstSeenMillis': now,
              'versionName': '1.0',
              'permissions': <String>[],
            },
          },
        }),
      );
      expect(
        await BaselineStore(
          dir.path,
        ).installedWithin(const Duration(hours: 12), nowMillis: now),
        {'com.legacy'},
      );
    });
  });
}
