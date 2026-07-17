/// Configuración persistente de la app — Dart puro (`dart:io` + JSON).
///
/// Equivalente móvil de la configuración de la edición Windows: idioma,
/// intervalo de auto-captura y umbrales de detección modificables. Vive en
/// un JSON del sandbox; un archivo corrupto degrada a valores por defecto.
library;

import 'dart:convert';
import 'dart:io';

import 'rule_engine.dart';

class AppConfig {
  const AppConfig({
    this.spanish = true,
    this.autoRefreshMinutes = 5,
    this.backgroundCapture = false,
    this.backgroundChargingOnly = true,
    this.memoryWarningPct = 20,
    this.memoryCriticalPct = 10,
    this.storageWarningPct = 15,
    this.storageCriticalPct = 5,
    this.batteryTempWarningCelsius = 40,
    this.batteryTempCriticalCelsius = 45,
  });

  factory AppConfig.fromMap(Map<String, dynamic> map) {
    int asInt(Object? v, int fallback) => v is num ? v.toInt() : fallback;
    bool asBool(Object? v, bool fallback) => v is bool ? v : fallback;
    const d = AppConfig();
    return AppConfig(
      spanish: asBool(map['spanish'], d.spanish),
      autoRefreshMinutes: asInt(
        map['autoRefreshMinutes'],
        d.autoRefreshMinutes,
      ),
      backgroundCapture: asBool(map['backgroundCapture'], d.backgroundCapture),
      backgroundChargingOnly: asBool(
        map['backgroundChargingOnly'],
        d.backgroundChargingOnly,
      ),
      memoryWarningPct: asInt(map['memoryWarningPct'], d.memoryWarningPct),
      memoryCriticalPct: asInt(map['memoryCriticalPct'], d.memoryCriticalPct),
      storageWarningPct: asInt(map['storageWarningPct'], d.storageWarningPct),
      storageCriticalPct: asInt(
        map['storageCriticalPct'],
        d.storageCriticalPct,
      ),
      batteryTempWarningCelsius: asInt(
        map['batteryTempWarningCelsius'],
        d.batteryTempWarningCelsius,
      ),
      batteryTempCriticalCelsius: asInt(
        map['batteryTempCriticalCelsius'],
        d.batteryTempCriticalCelsius,
      ),
    );
  }

  final bool spanish;

  /// 0 = auto-captura apagada; el original de escritorio usa 5 minutos.
  final int autoRefreshMinutes;
  final bool backgroundCapture;
  final bool backgroundChargingOnly;
  final int memoryWarningPct;
  final int memoryCriticalPct;
  final int storageWarningPct;
  final int storageCriticalPct;
  final int batteryTempWarningCelsius;
  final int batteryTempCriticalCelsius;

  RuleThresholds get thresholds => RuleThresholds(
    memoryWarningRatio: memoryWarningPct / 100,
    memoryCriticalRatio: memoryCriticalPct / 100,
    storageWarningRatio: storageWarningPct / 100,
    storageCriticalRatio: storageCriticalPct / 100,
    batteryTempWarningCelsius: batteryTempWarningCelsius.toDouble(),
    batteryTempCriticalCelsius: batteryTempCriticalCelsius.toDouble(),
  );

  AppConfig copyWith({
    bool? spanish,
    int? autoRefreshMinutes,
    bool? backgroundCapture,
    bool? backgroundChargingOnly,
    int? memoryWarningPct,
    int? memoryCriticalPct,
    int? storageWarningPct,
    int? storageCriticalPct,
    int? batteryTempWarningCelsius,
    int? batteryTempCriticalCelsius,
  }) => AppConfig(
    spanish: spanish ?? this.spanish,
    autoRefreshMinutes: autoRefreshMinutes ?? this.autoRefreshMinutes,
    backgroundCapture: backgroundCapture ?? this.backgroundCapture,
    backgroundChargingOnly:
        backgroundChargingOnly ?? this.backgroundChargingOnly,
    memoryWarningPct: memoryWarningPct ?? this.memoryWarningPct,
    memoryCriticalPct: memoryCriticalPct ?? this.memoryCriticalPct,
    storageWarningPct: storageWarningPct ?? this.storageWarningPct,
    storageCriticalPct: storageCriticalPct ?? this.storageCriticalPct,
    batteryTempWarningCelsius:
        batteryTempWarningCelsius ?? this.batteryTempWarningCelsius,
    batteryTempCriticalCelsius:
        batteryTempCriticalCelsius ?? this.batteryTempCriticalCelsius,
  );

  Map<String, Object?> toMap() => {
    'spanish': spanish,
    'autoRefreshMinutes': autoRefreshMinutes,
    'backgroundCapture': backgroundCapture,
    'backgroundChargingOnly': backgroundChargingOnly,
    'memoryWarningPct': memoryWarningPct,
    'memoryCriticalPct': memoryCriticalPct,
    'storageWarningPct': storageWarningPct,
    'storageCriticalPct': storageCriticalPct,
    'batteryTempWarningCelsius': batteryTempWarningCelsius,
    'batteryTempCriticalCelsius': batteryTempCriticalCelsius,
  };
}

class ConfigStore {
  ConfigStore(this.directoryPath);

  final String directoryPath;

  File get _file => File('$directoryPath/rootcause-config.json');

  /// Archivo heredado de v0.1.x que solo guardaba el idioma; se migra al
  /// config unificado la primera vez que se guarda.
  File get _legacyLanguageFile => File('$directoryPath/rootcause-language');

  Future<AppConfig> load() async {
    try {
      final file = _file;
      if (await file.exists()) {
        final map = jsonDecode(await file.readAsString());
        if (map is Map<String, dynamic>) return AppConfig.fromMap(map);
      }
      final legacy = _legacyLanguageFile;
      if (await legacy.exists()) {
        final code = (await legacy.readAsString()).trim();
        return AppConfig(spanish: code != 'en');
      }
    } on FileSystemException {
      // Sin acceso al disco se opera con los valores por defecto.
    } on FormatException {
      // Config corrupto: valores por defecto, sin crash.
    }
    return const AppConfig();
  }

  Future<void> save(AppConfig config) async {
    try {
      final file = _file;
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(config.toMap()), flush: true);
      final legacy = _legacyLanguageFile;
      if (await legacy.exists()) await legacy.delete();
    } on FileSystemException {
      // La configuración aplica en la sesión aunque no se pueda persistir.
    }
  }
}
