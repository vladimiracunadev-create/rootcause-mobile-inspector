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
  });

  final Snapshot snapshot;
  final Verdict verdict;
  final List<HistoryRow> history;

  /// `true` solo en la TRANSICIÓN a crítico (la captura anterior no lo
  /// era): así la alerta avisa una vez, no cada 15 minutos.
  final bool wentCritical;
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
    var newApps = const <AppRisk>[];
    HistoryStore? store;
    if (directoryPath != null) {
      store = HistoryStore(directoryPath);
      try {
        prior = await store.recent();
        newApps = await BaselineStore(directoryPath).diffAndUpdate(
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
    ).evaluate(snapshot, history: prior, newApps: newApps);

    final wentCritical =
        verdict.severity == Severity.critical &&
        (prior.isEmpty || prior.first.severity != Severity.critical);

    var history = prior;
    if (store != null) {
      try {
        await store.append(SnapshotJson.toJsonLine(snapshot, verdict));
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
    );
  }
}
