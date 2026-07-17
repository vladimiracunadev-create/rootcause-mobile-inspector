import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';
import 'package:rootcause_mobile_inspector/core/snapshot_json.dart';

import 'helpers.dart';

void main() {
  group('VolumeInfo — volúmenes adicionales (SD/USB)', () {
    test('sin campo volumes degrada a lista vacía (teléfono sin tarjeta)', () {
      final storage = StorageInfo.fromMap(const {
        'totalBytes': 100,
        'freeBytes': 50,
        'appCacheBytes': 1,
      });
      expect(storage.volumes, isEmpty);
    });

    test('parsea volúmenes del nativo con defaults defensivos', () {
      final storage = StorageInfo.fromMap(const {
        'totalBytes': 100,
        'freeBytes': 50,
        'appCacheBytes': 1,
        'volumes': [
          {
            'label': 'Tarjeta SD',
            'totalBytes': 32000,
            'freeBytes': 8000,
            'removable': true,
          },
          {'basura': true},
          'no soy un mapa',
        ],
      });
      expect(storage.volumes, hasLength(2));
      final sd = storage.volumes.first;
      expect(sd.label, 'Tarjeta SD');
      expect(sd.removable, isTrue);
      expect(sd.freeRatio, closeTo(0.25, 0.0001));
      // La entrada basura degrada a valores neutros, nunca a crash.
      expect(storage.volumes[1].totalBytes, 0);
    });

    test('el export JSON incluye los volúmenes', () {
      final snapshot = buildSnapshot(
        storage: const StorageInfo(
          totalBytes: 100,
          freeBytes: 50,
          appCacheBytes: 1,
          volumes: [
            VolumeInfo(
              label: 'SD',
              totalBytes: 32000,
              freeBytes: 8000,
              removable: true,
            ),
          ],
        ),
      );
      final verdict = const RuleEngine().evaluate(snapshot);
      final map =
          jsonDecode(SnapshotJson.toJson(snapshot, verdict))
              as Map<String, dynamic>;
      final volumes = (map['storage'] as Map)['volumes'] as List;
      expect(volumes, hasLength(1));
      expect((volumes.single as Map)['label'], 'SD');
      expect((volumes.single as Map)['removable'], true);
    });
  });
}
