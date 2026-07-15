import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';
import 'package:rootcause_mobile_inspector/core/snapshot_json.dart';

import 'helpers.dart';

void main() {
  const engine = RuleEngine();

  test('el export es JSON válido con schemaVersion y veredicto', () {
    final snapshot = buildSnapshot();
    final verdict = engine.evaluate(snapshot);
    final decoded =
        jsonDecode(SnapshotJson.toJson(snapshot, verdict))
            as Map<String, dynamic>;

    expect(decoded['schemaVersion'], SnapshotJson.schemaVersion);
    expect(decoded['timestampMillis'], snapshot.timestampMillis);
    expect((decoded['verdict'] as Map)['severity'], 'normal');
    expect(
      decoded.keys,
      containsAll(<String>[
        'findings',
        'memory',
        'storage',
        'battery',
        'network',
        'apps',
        'device',
      ]),
    );
  });

  test(
    'los ids de hallazgo se exportan sin traducir (neutrales al idioma)',
    () {
      final snapshot = buildSnapshot(
        memory: const MemoryInfo(
          totalBytes: 100,
          availableBytes: 5,
          lowMemory: false,
        ),
      );
      final verdict = engine.evaluate(snapshot);
      final decoded =
          jsonDecode(SnapshotJson.toJson(snapshot, verdict))
              as Map<String, dynamic>;

      final findings = decoded['findings'] as List;
      expect((findings.single as Map)['id'], 'mem-pressure');
      expect((findings.single as Map)['severity'], 'critical');
    },
  );

  test('toJsonLine produce una sola línea compacta y parseable', () {
    final snapshot = buildSnapshot();
    final verdict = engine.evaluate(snapshot);
    final line = SnapshotJson.toJsonLine(snapshot, verdict);

    expect(line.contains('\n'), isFalse);
    expect(jsonDecode(line), isA<Map<String, dynamic>>());
  });

  test('caracteres especiales en etiquetas no rompen el JSON', () {
    final snapshot = buildSnapshot(
      apps: [
        buildAppRisk(
          label: 'App "rara"\ncon saltos\\y barras',
          dangerousPermissions: const ['CAMERA'],
        ),
      ],
    );
    final verdict = engine.evaluate(snapshot);
    final decoded =
        jsonDecode(SnapshotJson.toJson(snapshot, verdict))
            as Map<String, dynamic>;
    final apps = decoded['apps'] as List;
    expect((apps.single as Map)['label'], 'App "rara"\ncon saltos\\y barras');
  });
}
