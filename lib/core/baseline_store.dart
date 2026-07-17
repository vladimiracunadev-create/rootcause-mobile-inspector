/// Baseline de apps instaladas — Dart puro (`dart:io` + JSON).
///
/// El equivalente móvil del `persistence-change` de la edición Windows:
/// el malware llega instalándose, así que la app NUEVA entre capturas es
/// la señal forense que interesa. El baseline guarda qué paquetes se han
/// visto y cuándo aparecieron; cada captura se compara contra él.
///
/// Reglas de honestidad:
/// - La PRIMERA captura inicializa el baseline en silencio (todo lo ya
///   instalado no es "nuevo": no hay evidencia de cuándo llegó).
/// - Una app desinstalada se poda del baseline: si se reinstala, vuelve a
///   contar como nueva (una reinstalación también es un evento).
/// - En iOS (`appsAuditSupported=false`) no se crea baseline: sin lista
///   de apps no hay nada honesto que comparar.
library;

import 'dart:convert';
import 'dart:io';

import 'models.dart';

class BaselineStore {
  BaselineStore(this.directoryPath);

  final String directoryPath;

  File get _file => File('$directoryPath/rootcause-apps-baseline.json');

  /// Compara [current] contra el baseline y lo actualiza en disco.
  /// Devuelve las apps NUEVAS desde la última captura (vacío en la
  /// primera ejecución, cuando el baseline recién se crea).
  Future<List<AppRisk>> diffAndUpdate(
    List<AppRisk> current, {
    required int nowMillis,
    required bool auditSupported,
  }) async {
    if (!auditSupported) return const [];
    try {
      final file = _file;
      final existing = await _load(file);
      if (existing == null) {
        // Primera vez: se registra lo presente, sin acusar a nadie.
        await _save(file, {
          for (final app in current) app.packageName: nowMillis,
        });
        return const [];
      }

      final newApps = current
          .where((a) => !existing.containsKey(a.packageName))
          .toList();
      final updated = <String, int>{
        for (final app in current)
          app.packageName: existing[app.packageName] ?? nowMillis,
      };
      await _save(file, updated);
      return newApps;
    } on FileSystemException {
      // Sin disco no hay baseline; la captura en vivo sigue funcionando.
      return const [];
    }
  }

  Future<Map<String, int>?> _load(File file) async {
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final packages = decoded is Map ? decoded['packages'] : null;
      if (packages is! Map) return null;
      return {
        for (final entry in packages.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
    } on FormatException {
      // Baseline corrupto: se reconstruye desde cero (sin acusaciones).
      return null;
    }
  }

  Future<void> _save(File file, Map<String, int> packages) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'packages': packages}), flush: true);
  }
}
