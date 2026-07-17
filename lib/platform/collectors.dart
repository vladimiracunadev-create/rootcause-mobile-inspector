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

  /// Abre la pantalla del sistema donde el usuario SÍ puede intervenir
  /// (liberar espacio, uso de batería, ficha de una app). Devuelve `false`
  /// si la plataforma no tiene esa pantalla — la UI lo comunica, no finge.
  Future<bool> openSystemScreen(String screen, {String? packageName}) async {
    try {
      final ok = await _channel.invokeMethod<bool>('openSystemScreen', {
        'screen': screen,
        'packageName': ?packageName,
      });
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Borra la caché propia de RootCause. Devuelve los bytes liberados
  /// (0 si no había nada o el nativo no está disponible).
  Future<int> clearOwnCache() async {
    try {
      return await _channel.invokeMethod<int>('clearOwnCache') ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  /// Pide los permisos de escaneo Bluetooth en tiempo de ejecución.
  /// Devuelve `true` si quedaron concedidos.
  Future<bool> requestBlePermissions() async {
    try {
      return await _channel.invokeMethod<bool>('requestBlePermissions') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Escaneo BLE manual de [seconds] segundos. Devuelve la lista cruda de
  /// dispositivos (`address`, `name`, `rssi`) o `null` si la plataforma no
  /// lo soporta o falta el permiso.
  Future<List<Object?>?> bleScan({int seconds = 15}) async {
    try {
      return await _channel.invokeMethod<List<Object?>>('bleScan', {
        'seconds': seconds,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Pide el permiso de notificaciones (Android 13+; en versiones previas
  /// no existe y se considera concedido). `false` si el usuario lo negó.
  Future<bool> requestNotificationPermissions() async {
    try {
      return await _channel.invokeMethod<bool>(
            'requestNotificationPermissions',
          ) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Notificación LOCAL de veredicto crítico (sin INTERNET no existe el
  /// push; esto es una notificación del propio dispositivo). `false` si
  /// falta el permiso o la plataforma no lo soporta.
  Future<bool> notifyCritical({
    required String title,
    required String body,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('notifyCritical', {
            'title': title,
            'body': body,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Refresca el widget de pantalla de inicio con la última captura del
  /// historial. Silencioso donde no hay widget (iOS, tests).
  Future<void> refreshWidget() async {
    try {
      await _channel.invokeMethod<void>('refreshWidget');
    } on PlatformException {
      // Sin widget instalado no hay nada que refrescar.
    } on MissingPluginException {
      // Sin lado nativo (tests).
    }
  }

  /// Programa (o cancela) la captura periódica en segundo plano. Android la
  /// ejecuta con WorkManager (mínimo 15 minutos, impuesto por el SO);
  /// devuelve `false` donde no está soportado (iOS, tests).
  Future<bool> configureBackgroundCapture({
    required bool enabled,
    required bool chargingOnly,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'configureBackgroundCapture',
        {'enabled': enabled, 'chargingOnly': chargingOnly},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
