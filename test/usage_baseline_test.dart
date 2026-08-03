/// Tests de la línea base de USO por app (v0.8.0) — el salto de superficie
/// declarada a comportamiento observado.
///
/// Lo que se verifica aquí no es "detecta picos", sino las reglas de
/// honestidad: no acusar sin referencia independiente, no confundir ruido
/// con señal, y no interpretar "sin dato" como cero.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/usage_baseline.dart';

import 'helpers.dart';

const _hour = 3600 * 1000;
const _mb = 1024 * 1024;

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rootcause-usage-test');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// Escribe un historial sintético: [count] muestras separadas una hora,
  /// terminando [endsHoursAgo] horas antes de [nowMillis].
  Future<void> seed(
    String packageName, {
    required int nowMillis,
    required int count,
    required int dataBytes,
    int screenMillis = -1,
    int endsHoursAgo = 25,
  }) async {
    final samples = [
      for (var i = count - 1; i >= 0; i--)
        {
          't': nowMillis - (endsHoursAgo + i) * _hour,
          'd': dataBytes,
          'f': screenMillis,
        },
    ];
    await File('${dir.path}/rootcause-usage-baseline.json').writeAsString(
      jsonEncode({
        'packages': {packageName: samples},
      }),
    );
  }

  test('sin muestras independientes no acusa a nadie', () async {
    const now = 1700000000000;
    // Historial abundante pero TODO dentro de las últimas 24 h: el propio
    // pico contaminaría su referencia, así que la regla se omite.
    await seed(
      'com.spy',
      nowMillis: now,
      count: 10,
      dataBytes: 1 * _mb,
      endsHoursAgo: 1,
    );
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.spy',
          rxBytes24h: 900 * _mb,
          txBytes24h: 0,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies, isEmpty);
  });

  test('detecta el salto de datos contra el hábito de la propia app', () async {
    const now = 1700000000000;
    await seed('com.spy', nowMillis: now, count: 5, dataBytes: 20 * _mb);
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.spy',
          label: 'Notas',
          rxBytes24h: 700 * _mb,
          txBytes24h: 0,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );

    expect(anomalies, hasLength(1));
    expect(anomalies.single.metric, UsageMetric.data);
    expect(anomalies.single.baselineValue, 20 * _mb);
    expect(anomalies.single.factor, greaterThan(3));
    expect(anomalies.single.hasActiveCapability, isFalse);
  });

  test('un múltiplo alto por debajo del suelo es ruido, no señal', () async {
    const now = 1700000000000;
    // De 1 MB a 10 MB son ×10 y no significan nada.
    await seed('com.chat', nowMillis: now, count: 5, dataBytes: 1 * _mb);
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.chat',
          rxBytes24h: 10 * _mb,
          txBytes24h: 0,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies, isEmpty);
  });

  test('línea base cero: pasar de nada a mucho ES la anomalía', () async {
    const now = 1700000000000;
    await seed('com.quiet', nowMillis: now, count: 4, dataBytes: 0);
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.quiet',
          rxBytes24h: 300 * _mb,
          txBytes24h: 0,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies, hasLength(1));
    // Sin referencia positiva no hay múltiplo definido: 0, no infinito.
    expect(anomalies.single.factor, 0);
  });

  test('la mediana ignora un único día raro', () async {
    const now = 1700000000000;
    // Cuatro muestras de 10 MB y una de 900 MB: la mediana sigue en 10 MB,
    // así que un consumo actual de 100 MB sigue siendo anomalía.
    final samples = [
      for (var i = 0; i < 4; i++)
        {'t': now - (30 + i) * _hour, 'd': 10 * _mb, 'f': -1},
      {'t': now - 26 * _hour, 'd': 900 * _mb, 'f': -1},
    ];
    await File('${dir.path}/rootcause-usage-baseline.json').writeAsString(
      jsonEncode({
        'packages': {'com.app': samples},
      }),
    );

    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.app',
          rxBytes24h: 100 * _mb,
          txBytes24h: 0,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies, hasLength(1));
    expect(anomalies.single.baselineValue, 10 * _mb);
  });

  test('sin acceso de uso (-1) no se inventa un cero', () async {
    const now = 1700000000000;
    await seed('com.app', nowMillis: now, count: 5, dataBytes: 20 * _mb);
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        // rx/tx = -1: el SO no entregó el dato.
        buildAppRisk(packageName: 'com.app'),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies, isEmpty);
  });

  test('en iOS (sin auditoría de apps) la regla no corre', () async {
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [buildAppRisk(rxBytes24h: 900 * _mb, txBytes24h: 0)],
      nowMillis: 1700000000000,
      auditSupported: false,
    );
    expect(anomalies, isEmpty);
    expect(
      await File('${dir.path}/rootcause-usage-baseline.json').exists(),
      isFalse,
    );
  });

  test('el muestreo respeta el intervalo y no engorda el archivo', () async {
    const now = 1700000000000;
    final store = UsageBaselineStore(dir.path);
    final app = buildAppRisk(rxBytes24h: 5 * _mb, txBytes24h: 0);

    // Doce capturas de 5 minutos dentro de la misma hora → 1 sola muestra.
    for (var i = 0; i < 12; i++) {
      await store.updateAndDetect(
        [app],
        nowMillis: now + i * 5 * 60 * 1000,
        auditSupported: true,
      );
    }
    final decoded =
        jsonDecode(
              await File(
                '${dir.path}/rootcause-usage-baseline.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    final samples =
        (decoded['packages'] as Map)[app.packageName] as List<dynamic>;
    expect(samples, hasLength(1));
  });

  test('desinstalar una app borra su historial de uso', () async {
    const now = 1700000000000;
    final store = UsageBaselineStore(dir.path);
    await store.updateAndDetect(
      [
        buildAppRisk(packageName: 'com.gone', rxBytes24h: 1, txBytes24h: 0),
        buildAppRisk(packageName: 'com.stays', rxBytes24h: 1, txBytes24h: 0),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    await store.updateAndDetect(
      [buildAppRisk(packageName: 'com.stays', rxBytes24h: 1, txBytes24h: 0)],
      nowMillis: now + 2 * _hour,
      auditSupported: true,
    );

    final decoded =
        jsonDecode(
              await File(
                '${dir.path}/rootcause-usage-baseline.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    expect((decoded['packages'] as Map).containsKey('com.gone'), isFalse);
    expect((decoded['packages'] as Map).containsKey('com.stays'), isTrue);
  });

  test('un archivo corrupto se reconstruye sin crash', () async {
    await File(
      '${dir.path}/rootcause-usage-baseline.json',
    ).writeAsString('{ esto no es json');
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [buildAppRisk(rxBytes24h: 900 * _mb, txBytes24h: 0)],
      nowMillis: 1700000000000,
      auditSupported: true,
    );
    expect(anomalies, isEmpty);
  });

  test('capacidad de espionaje activa se marca en la anomalía', () async {
    const now = 1700000000000;
    await seed('com.spy', nowMillis: now, count: 5, dataBytes: 10 * _mb);
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.spy',
          specialFlags: const ['accessibility-service'],
          rxBytes24h: 500 * _mb,
          txBytes24h: 0,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies.single.hasActiveCapability, isTrue);
  });

  test('anomalía de tiempo en pantalla cuando no hay dato de datos', () async {
    const now = 1700000000000;
    await seed(
      'com.app',
      nowMillis: now,
      count: 5,
      dataBytes: -1,
      screenMillis: 10 * 60 * 1000,
    );
    final anomalies = await UsageBaselineStore(dir.path).updateAndDetect(
      [
        buildAppRisk(
          packageName: 'com.app',
          foregroundMillis24h: 4 * 60 * 60 * 1000,
        ),
      ],
      nowMillis: now,
      auditSupported: true,
    );
    expect(anomalies, hasLength(1));
    expect(anomalies.single.metric, UsageMetric.screen);
  });
}
