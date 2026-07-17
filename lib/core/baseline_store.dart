/// Baseline de apps instaladas — Dart puro (`dart:io` + JSON).
///
/// El equivalente móvil del `persistence-change` de la edición Windows,
/// desde v0.5.0 con el ciclo de vida completo: NUEVA (no estaba),
/// ACTUALIZADA (cambió de versión) y ELIMINADA (ya no está). La app
/// nueva es hallazgo; las otras dos son contexto informativo.
///
/// Reglas de honestidad:
/// - La PRIMERA captura inicializa el baseline en silencio (todo lo ya
///   instalado no es "nuevo": no hay evidencia de cuándo llegó).
/// - Una app desinstalada se poda: si se reinstala, vuelve a contar como
///   nueva (una reinstalación también es un evento).
/// - En iOS (`appsAuditSupported=false`) no se crea baseline.
library;

import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Resultado de comparar una captura contra el baseline.
class BaselineDiff {
  const BaselineDiff({
    this.newApps = const [],
    this.updatedApps = const [],
    this.removedPackages = const [],
  });

  final List<AppRisk> newApps;

  /// Apps cuya versión cambió desde la captura anterior.
  final List<AppRisk> updatedApps;

  /// Paquetes que estaban en el baseline y ya no están instalados.
  final List<String> removedPackages;

  bool get isEmpty =>
      newApps.isEmpty && updatedApps.isEmpty && removedPackages.isEmpty;
}

class BaselineStore {
  BaselineStore(this.directoryPath);

  final String directoryPath;

  File get _file => File('$directoryPath/rootcause-apps-baseline.json');

  /// Compara [current] contra el baseline, lo actualiza en disco y
  /// devuelve el diff completo (vacío en la primera ejecución).
  Future<BaselineDiff> diffAndUpdate(
    List<AppRisk> current, {
    required int nowMillis,
    required bool auditSupported,
  }) async {
    if (!auditSupported) return const BaselineDiff();
    try {
      final file = _file;
      final existing = await _load(file);
      if (existing == null) {
        // Primera vez: se registra lo presente, sin acusar a nadie.
        await _save(file, {
          for (final app in current)
            app.packageName: _Entry(nowMillis, app.versionName),
        });
        return const BaselineDiff();
      }

      final newApps = <AppRisk>[];
      final updatedApps = <AppRisk>[];
      for (final app in current) {
        final entry = existing[app.packageName];
        if (entry == null) {
          newApps.add(app);
        } else if (entry.versionName != '?' &&
            app.versionName != '?' &&
            entry.versionName != app.versionName) {
          // Un baseline migrado de v0.3/v0.4 (sin versión) no acusa de
          // "actualizada" a media biblioteca: registra y sigue.
          updatedApps.add(app);
        }
      }
      final currentPackages = {for (final a in current) a.packageName};
      final removed = existing.keys
          .where((pkg) => !currentPackages.contains(pkg))
          .toList();

      await _save(file, {
        for (final app in current)
          app.packageName: _Entry(
            existing[app.packageName]?.firstSeenMillis ?? nowMillis,
            app.versionName,
          ),
      });
      return BaselineDiff(
        newApps: newApps,
        updatedApps: updatedApps,
        removedPackages: removed,
      );
    } on FileSystemException {
      // Sin disco no hay baseline; la captura en vivo sigue funcionando.
      return const BaselineDiff();
    }
  }

  Future<Map<String, _Entry>?> _load(File file) async {
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final packages = decoded is Map ? decoded['packages'] : null;
      if (packages is! Map) return null;
      final result = <String, _Entry>{};
      for (final entry in packages.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String) continue;
        if (value is num) {
          // Formato v0.3/v0.4 (solo firstSeen): migra sin perder fechas.
          result[key] = _Entry(value.toInt(), '?');
        } else if (value is Map) {
          result[key] = _Entry(
            value['firstSeenMillis'] is num
                ? (value['firstSeenMillis'] as num).toInt()
                : 0,
            value['versionName'] is String
                ? value['versionName'] as String
                : '?',
          );
        }
      }
      return result;
    } on FormatException {
      // Baseline corrupto: se reconstruye desde cero (sin acusaciones).
      return null;
    }
  }

  Future<void> _save(File file, Map<String, _Entry> packages) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'packages': {
          for (final entry in packages.entries)
            entry.key: {
              'firstSeenMillis': entry.value.firstSeenMillis,
              'versionName': entry.value.versionName,
            },
        },
      }),
      flush: true,
    );
  }
}

class _Entry {
  const _Entry(this.firstSeenMillis, this.versionName);

  final int firstSeenMillis;
  final String versionName;
}
