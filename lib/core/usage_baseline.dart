/// Línea base de USO por app — Dart puro (`dart:io` + JSON).
///
/// El salto de v0.8.0: hasta aquí el motor evaluaba **superficie declarada**
/// (qué permisos pide una app) y **recursos globales** (cuánta RAM queda).
/// Esto evalúa **comportamiento observado**: cuánto consume cada app
/// comparada consigo misma, no con un umbral inventado.
///
/// La pregunta que responde es la que ningún umbral absoluto contesta:
/// *¿esta app está haciendo hoy algo que no hacía antes?* Una app de notas
/// que siempre gastó 2 MB al día y hoy sube 700 MB no viola ningún umbral
/// global — pero se delata contra su propio hábito.
///
/// Reglas de honestidad (las mismas que el resto del sensor):
/// - El SO entrega ventanas MÓVILES de 24 h. Por eso la línea base se
///   construye SOLO con muestras anteriores a esas 24 h ([baselineLag]): si
///   se mezclaran, el propio pico contaminaría su referencia y la anomalía
///   se escondería sola.
/// - Sin muestras suficientes fuera de esa ventana la regla se OMITE, no se
///   inventa. Un teléfono recién instalado no acusa a nadie.
/// - La mediana (no la media) es la referencia: un único día raro no
///   redefine lo normal.
/// - Requiere el acceso de uso (opt-in real del usuario). Sin él los
///   colectores entregan -1 y aquí no se registra nada.
library;

import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Métrica de uso que disparó la anomalía.
enum UsageMetric {
  /// Datos (rx+tx) de las últimas 24 h medidos por el SO.
  data,

  /// Tiempo en primer plano de las últimas 24 h medido por el SO.
  screen,
}

/// Una app cuyo consumo actual se despega de su propio hábito histórico.
class AppUsageAnomaly {
  const AppUsageAnomaly({
    required this.app,
    required this.metric,
    required this.baselineValue,
    required this.currentValue,
  });

  final AppRisk app;
  final UsageMetric metric;

  /// Mediana histórica (bytes o milisegundos según [metric]).
  final int baselineValue;

  /// Valor de esta captura, en la misma unidad que [baselineValue].
  final int currentValue;

  /// Cuántas veces se multiplicó respecto de la línea base. Con línea base
  /// 0 (la app nunca había consumido) no hay múltiplo definido: devuelve 0
  /// y la UI lo comunica como "no lo hacía antes", que es más honesto que
  /// un infinito.
  double get factor => baselineValue > 0 ? currentValue / baselineValue : 0;

  /// `true` si la app tiene además una capacidad de espionaje CONCEDIDA y
  /// activa (accesibilidad, lector de notificaciones, admin). Consumo
  /// anómalo + capacidad real es la coincidencia que más importa.
  bool get hasActiveCapability => app.activeCapabilities.isNotEmpty;
}

class UsageBaselineStore {
  UsageBaselineStore(
    this.directoryPath, {
    this.sampleInterval = const Duration(hours: 1),
    this.maxSamplesPerApp = 48,
  });

  final String directoryPath;

  /// Cada cuánto se registra una muestra por app. Con auto-captura de 5
  /// minutos, guardar todas las capturas engordaría el archivo sin añadir
  /// información: la ventana del SO es de 24 h y se mueve despacio.
  final Duration sampleInterval;

  /// Muestras retenidas por app. 48 muestras × 1 h = 48 h de cobertura, lo
  /// justo para que exista referencia anterior a la ventana de 24 h.
  final int maxSamplesPerApp;

  /// Antigüedad mínima de una muestra para servir de línea base: las
  /// ventanas del SO son de 24 h, así que solo lo anterior a eso es
  /// independiente de lo que se está midiendo ahora.
  static const Duration baselineLag = Duration(hours: 24);

  /// Muestras independientes mínimas para pronunciarse.
  static const int minBaselineSamples = 3;

  /// Cuántas veces debe multiplicarse el consumo para ser anomalía.
  static const double anomalyFactor = 3.0;

  /// Suelos absolutos: por debajo de esto un múltiplo alto es ruido
  /// (pasar de 1 MB a 5 MB es ×5 y no significa nada).
  static const int dataFloorBytes = 50 * 1024 * 1024; // 50 MB
  static const int screenFloorMillis = 30 * 60 * 1000; // 30 min

  File get _file => File('$directoryPath/rootcause-usage-baseline.json');

  /// Compara el uso actual contra la línea base de cada app, registra la
  /// muestra de esta captura y devuelve las anomalías.
  ///
  /// Devuelve lista vacía —nunca lanza— si la plataforma no soporta la
  /// auditoría (iOS), si falta el acceso de uso o si no hay disco.
  Future<List<AppUsageAnomaly>> updateAndDetect(
    List<AppRisk> apps, {
    required int nowMillis,
    required bool auditSupported,
  }) async {
    if (!auditSupported || apps.isEmpty) return const [];
    try {
      final file = _file;
      final stored = await _load(file);
      final anomalies = <AppUsageAnomaly>[];
      final updated = <String, List<_Sample>>{};

      for (final app in apps) {
        final history = stored[app.packageName] ?? const <_Sample>[];
        final data = app.dataBytes24h;
        final screen = app.foregroundMillis24h;

        // Solo se evalúa lo que el SO realmente entregó (-1 = sin acceso
        // de uso): la ausencia de dato jamás se interpreta como cero.
        final anomaly = _detect(app, history, nowMillis, data, screen);
        if (anomaly != null) anomalies.add(anomaly);

        updated[app.packageName] = _record(
          history,
          nowMillis: nowMillis,
          data: data,
          screen: screen,
        );
      }

      await _save(file, updated);
      // Las más llamativas primero: capacidad activa, luego múltiplo.
      anomalies.sort((a, b) {
        if (a.hasActiveCapability != b.hasActiveCapability) {
          return a.hasActiveCapability ? -1 : 1;
        }
        return b.currentValue.compareTo(a.currentValue);
      });
      return anomalies;
    } on FileSystemException {
      // Sin disco no hay línea base; la captura en vivo sigue funcionando.
      return const [];
    }
  }

  /// La anomalía de datos tiene prioridad sobre la de pantalla: exfiltrar
  /// es un indicio más fuerte que estar abierta más rato.
  AppUsageAnomaly? _detect(
    AppRisk app,
    List<_Sample> history,
    int nowMillis,
    int data,
    int screen,
  ) {
    final cutoff = nowMillis - baselineLag.inMilliseconds;
    final independent = history.where((s) => s.timestamp <= cutoff).toList();
    if (independent.length < minBaselineSamples) return null;

    if (data >= 0) {
      final baseline = _median([
        for (final s in independent)
          if (s.data >= 0) s.data,
      ]);
      if (baseline != null && _isAnomalous(baseline, data, dataFloorBytes)) {
        return AppUsageAnomaly(
          app: app,
          metric: UsageMetric.data,
          baselineValue: baseline,
          currentValue: data,
        );
      }
    }
    if (screen >= 0) {
      final baseline = _median([
        for (final s in independent)
          if (s.screen >= 0) s.screen,
      ]);
      if (baseline != null &&
          _isAnomalous(baseline, screen, screenFloorMillis)) {
        return AppUsageAnomaly(
          app: app,
          metric: UsageMetric.screen,
          baselineValue: baseline,
          currentValue: screen,
        );
      }
    }
    return null;
  }

  /// Con línea base 0 (la app nunca consumió esto) basta con superar el
  /// suelo: pasar de nada a algo relevante ES la anomalía.
  bool _isAnomalous(int baseline, int current, int floor) {
    if (current < floor) return false;
    if (baseline <= 0) return true;
    return current >= baseline * anomalyFactor;
  }

  /// Mediana entera; `null` si no hay suficientes valores disponibles.
  int? _median(List<int> values) {
    if (values.length < minBaselineSamples) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) ~/ 2;
  }

  /// Añade la muestra de esta captura si ya pasó [sampleInterval] desde la
  /// última, y recorta a [maxSamplesPerApp] (se conservan las recientes).
  List<_Sample> _record(
    List<_Sample> history, {
    required int nowMillis,
    required int data,
    required int screen,
  }) {
    if (data < 0 && screen < 0) return history;
    final last = history.isNotEmpty ? history.last : null;
    if (last != null &&
        nowMillis - last.timestamp < sampleInterval.inMilliseconds) {
      return history;
    }
    final next = [...history, _Sample(nowMillis, data, screen)];
    return next.length <= maxSamplesPerApp
        ? next
        : next.sublist(next.length - maxSamplesPerApp);
  }

  Future<Map<String, List<_Sample>>> _load(File file) async {
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      final packages = decoded is Map ? decoded['packages'] : null;
      if (packages is! Map) return {};
      final result = <String, List<_Sample>>{};
      for (final entry in packages.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! List) continue;
        final samples = <_Sample>[];
        for (final raw in value) {
          if (raw is! Map) continue;
          final t = raw['t'];
          if (t is! num) continue;
          samples.add(
            _Sample(
              t.toInt(),
              raw['d'] is num ? (raw['d'] as num).toInt() : -1,
              raw['f'] is num ? (raw['f'] as num).toInt() : -1,
            ),
          );
        }
        samples.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        result[key] = samples;
      }
      return result;
    } on FormatException {
      // Archivo corrupto: se reconstruye desde cero, sin acusar a nadie.
      return {};
    }
  }

  /// Solo se persisten las apps de la captura actual: desinstalar una app
  /// borra su historial de uso (no se guarda evidencia de lo que ya no está).
  Future<void> _save(File file, Map<String, List<_Sample>> packages) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'packages': {
          for (final entry in packages.entries)
            if (entry.value.isNotEmpty)
              entry.key: [
                for (final s in entry.value)
                  {'t': s.timestamp, 'd': s.data, 'f': s.screen},
              ],
        },
      }),
      flush: true,
    );
  }
}

class _Sample {
  const _Sample(this.timestamp, this.data, this.screen);

  final int timestamp;

  /// Bytes rx+tx en 24 h; -1 si no estaba disponible en esa captura.
  final int data;

  /// Milisegundos en primer plano en 24 h; -1 si no estaba disponible.
  final int screen;
}
