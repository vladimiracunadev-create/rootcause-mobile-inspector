/// Flujo de captura unificado — lo ejecutan la app abierta y el Worker de
/// segundo plano con EXACTAMENTE la misma política: colecta, baseline de
/// apps, motor de reglas con historial, persistencia y detección de
/// transición a crítico. Cero copias que puedan divergir.
library;

import 'dart:io';

import '../core/baseline_store.dart';
import '../core/config_store.dart';
import '../core/history_store.dart';
import '../core/models.dart';
import '../core/rule_engine.dart';
import '../core/snapshot_json.dart';
import 'collectors.dart';

class CaptureOutcome {
  const CaptureOutcome({
    required this.snapshot,
    required this.verdict,
    required this.history,
    required this.wentCritical,
    this.baselineDiff = const BaselineDiff(),
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final List<HistoryRow> history;

  /// `true` solo en la TRANSICIÓN a crítico (la captura anterior no lo
  /// era): así la alerta avisa una vez, no cada 15 minutos.
  final bool wentCritical;

  /// Ciclo de vida de apps desde la captura anterior (nuevas /
  /// actualizadas / eliminadas).
  final BaselineDiff baselineDiff;

  /// Apps nuevas con superficie riesgosa o sideload — el caso que
  /// merece notificación aunque el veredicto global no sea crítico.
  List<AppRisk> get riskyNewApps => baselineDiff.newApps
      .where((a) => a.severity != Severity.normal || a.sideloaded)
      .toList();
}

class CaptureService {
  const CaptureService(this.collectors);

  final PlatformCollectors collectors;

  Future<CaptureOutcome> capture({
    required AppConfig config,
    String? directoryPath,
  }) async {
    final snapshot = await collectors.collect();

    var prior = const <HistoryRow>[];
    var diff = const BaselineDiff();
    HistoryStore? store;
    if (directoryPath != null) {
      store = HistoryStore(directoryPath);
      try {
        prior = await store.recent();
        diff = await BaselineStore(directoryPath).diffAndUpdate(
          snapshot.apps,
          nowMillis: snapshot.timestampMillis,
          auditSupported: snapshot.device.appsAuditSupported,
        );
      } on FileSystemException {
        // Sin historial/baseline no se bloquea el diagnóstico en vivo.
      }
    }

    final verdict = RuleEngine(
      thresholds: config.thresholds,
    ).evaluate(snapshot, history: prior, newApps: diff.newApps);

    final wentCritical =
        verdict.severity == Severity.critical &&
        (prior.isEmpty || prior.first.severity != Severity.critical);

    var history = prior;
    if (store != null) {
      try {
        // La captura se sella al anexarse (cadena de hashes) — ver
        // HistoryStore.append.
        await store.append(SnapshotJson.toMap(snapshot, verdict, diff: diff));
        history = await store.recent();
      } on FileSystemException {
        history = prior;
      }
    }

    return CaptureOutcome(
      snapshot: snapshot,
      verdict: verdict,
      history: history,
      wentCritical: wentCritical,
      baselineDiff: diff,
    );
  }
}
