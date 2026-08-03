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

/// Una app que GANÓ permisos peligrosos respecto del baseline anterior —
/// típicamente tras una actualización. Es el "¿qué cambió?" aplicado a los
/// permisos: una app que ya tenías, ahora pide el micrófono o la ubicación.
class AppPermGain {
  const AppPermGain({required this.app, required this.gained});

  final AppRisk app;

  /// Permisos peligrosos nuevos (constantes sin prefijo) que no estaban antes.
  final List<String> gained;
}

/// Resultado de comparar una captura contra el baseline.
class BaselineDiff {
  const BaselineDiff({
    this.newApps = const [],
    this.updatedApps = const [],
    this.removedPackages = const [],
    this.permissionGains = const [],
  });

  final List<AppRisk> newApps;

  /// Apps cuya versión cambió desde la captura anterior.
  final List<AppRisk> updatedApps;

  /// Paquetes que estaban en el baseline y ya no están instalados.
  final List<String> removedPackages;

  /// Apps ya conocidas que ganaron permisos peligrosos desde la captura
  /// anterior (escalada de superficie).
  final List<AppPermGain> permissionGains;

  bool get isEmpty =>
      newApps.isEmpty &&
      updatedApps.isEmpty &&
      removedPackages.isEmpty &&
      permissionGains.isEmpty;
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
      final loaded = await _load(file);
      if (loaded == null) {
        // Primera vez: se registra lo presente, sin acusar a nadie. La marca
        // `createdMillis` deja constancia de que esas fechas son de
        // inicialización, no de instalación observada.
        await _save(file, {
          for (final app in current)
            app.packageName: _Entry(
              nowMillis,
              app.versionName,
              app.dangerousPermissions,
            ),
        }, createdMillis: nowMillis);
        return const BaselineDiff();
      }
      final existing = loaded.packages;

      final newApps = <AppRisk>[];
      final updatedApps = <AppRisk>[];
      final permGains = <AppPermGain>[];
      for (final app in current) {
        final entry = existing[app.packageName];
        if (entry == null) {
          newApps.add(app);
          continue;
        }
        if (entry.versionName != '?' &&
            app.versionName != '?' &&
            entry.versionName != app.versionName) {
          // Un baseline migrado de v0.3/v0.4 (sin versión) no acusa de
          // "actualizada" a media biblioteca: registra y sigue.
          updatedApps.add(app);
        }
        // Escalada de permisos: solo si el baseline anterior YA registraba la
        // lista (null = entrada migrada sin permisos → no se acusa este turno,
        // se registran ahora para el próximo).
        final priorPerms = entry.permissions;
        if (priorPerms != null) {
          final priorSet = priorPerms.toSet();
          final gained = app.dangerousPermissions
              .where((p) => !priorSet.contains(p))
              .toList();
          if (gained.isNotEmpty) {
            permGains.add(AppPermGain(app: app, gained: gained));
          }
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
            app.dangerousPermissions,
          ),
      }, createdMillis: loaded.createdMillis);
      return BaselineDiff(
        newApps: newApps,
        updatedApps: updatedApps,
        removedPackages: removed,
        permissionGains: permGains,
      );
    } on FileSystemException {
      // Sin disco no hay baseline; la captura en vivo sigue funcionando.
      return const BaselineDiff();
    }
  }

  /// Paquetes cuya PRIMERA aparición observada cae dentro de [window]
  /// contando hacia atrás desde [nowMillis].
  ///
  /// Los que entraron con la inicialización del baseline se excluyen: de
  /// esos no sabemos cuándo se instalaron y señalarlos sería inventar una
  /// fecha. Es la misma honestidad que la "primera captura silenciosa".
  Future<Set<String>> installedWithin(
    Duration window, {
    required int nowMillis,
  }) async {
    try {
      final loaded = await _load(_file);
      if (loaded == null) return const {};
      final since = nowMillis - window.inMilliseconds;
      return {
        for (final entry in loaded.packages.entries)
          if (entry.value.firstSeenMillis >= since &&
              entry.value.firstSeenMillis != loaded.createdMillis)
            entry.key,
      };
    } on FileSystemException {
      return const {};
    }
  }

  Future<_Loaded?> _load(File file) async {
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final packages = decoded is Map ? decoded['packages'] : null;
      if (packages is! Map) return null;
      // Baselines anteriores a v0.8.0 no tienen la marca; con -1 ninguna
      // entrada coincide y todas se consideran de instalación observada.
      final created = decoded is Map && decoded['createdMillis'] is num
          ? (decoded['createdMillis'] as num).toInt()
          : -1;
      final result = <String, _Entry>{};
      for (final entry in packages.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String) continue;
        if (value is num) {
          // Formato v0.3/v0.4 (solo firstSeen): migra sin perder fechas.
          result[key] = _Entry(value.toInt(), '?', null);
        } else if (value is Map) {
          result[key] = _Entry(
            value['firstSeenMillis'] is num
                ? (value['firstSeenMillis'] as num).toInt()
                : 0,
            value['versionName'] is String
                ? value['versionName'] as String
                : '?',
            // `null` cuando el baseline es previo a v0.7.0 (sin permisos):
            // no se acusa de escalada hasta tener una referencia real.
            value['permissions'] is List
                ? (value['permissions'] as List).whereType<String>().toList()
                : null,
          );
        }
      }
      return _Loaded(result, created);
    } on FormatException {
      // Baseline corrupto: se reconstruye desde cero (sin acusaciones).
      return null;
    }
  }

  Future<void> _save(
    File file,
    Map<String, _Entry> packages, {
    required int createdMillis,
  }) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'createdMillis': createdMillis,
        'packages': {
          for (final entry in packages.entries)
            entry.key: {
              'firstSeenMillis': entry.value.firstSeenMillis,
              'versionName': entry.value.versionName,
              'permissions': entry.value.permissions ?? const <String>[],
            },
        },
      }),
      flush: true,
    );
  }
}

/// Baseline leído de disco: las entradas más la marca de inicialización.
class _Loaded {
  const _Loaded(this.packages, this.createdMillis);

  final Map<String, _Entry> packages;

  /// Instante en que se creó el baseline; -1 en archivos previos a v0.8.0.
  final int createdMillis;
}

class _Entry {
  const _Entry(this.firstSeenMillis, this.versionName, this.permissions);

  final int firstSeenMillis;
  final String versionName;

  /// Permisos peligrosos registrados; `null` en entradas migradas de antes
  /// de v0.7.0 (aún sin referencia para detectar escaladas).
  final List<String>? permissions;
}
