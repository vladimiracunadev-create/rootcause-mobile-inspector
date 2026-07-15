/// Puente al canal nativo `rootcause/collectors`.
///
/// Android (Kotlin) e iOS (Swift) implementan el método `collect` y
/// devuelven el mapa documentado en docs/ARCHITECTURE.md. Cualquier error
/// del nativo degrada a un snapshot vacío y seguro — nunca crash.
library;

import 'package:flutter/services.dart';

import '../core/models.dart';

class PlatformCollectors {
  const PlatformCollectors();

  static const MethodChannel _channel = MethodChannel('rootcause/collectors');

  Future<Snapshot> collect() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'collect',
      );
      return Snapshot.fromCollectorMap(
        result ?? const {},
        timestampMillis: now,
      );
    } on PlatformException {
      return Snapshot.fromCollectorMap(const {}, timestampMillis: now);
    } on MissingPluginException {
      return Snapshot.fromCollectorMap(const {}, timestampMillis: now);
    }
  }

  /// Directorio de documentos del sandbox de la app (historial y exports).
  /// `null` si el nativo no está disponible (p. ej. en tests de widget).
  Future<String?> documentsPath() async {
    try {
      return await _channel.invokeMethod<String>('documentsPath');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
