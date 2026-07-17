import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/config_store.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rootcause-config-test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('sin archivo devuelve los valores por defecto', () async {
    final config = await ConfigStore(tmp.path).load();
    expect(config.spanish, isTrue);
    expect(config.autoRefreshMinutes, 5);
    expect(config.backgroundCapture, isFalse);
    expect(config.backgroundChargingOnly, isTrue);
    expect(config.memoryWarningPct, 20);
    expect(config.storageCriticalPct, 5);
  });

  test('save + load hace round-trip completo', () async {
    final store = ConfigStore(tmp.path);
    const changed = AppConfig(
      spanish: false,
      autoRefreshMinutes: 15,
      backgroundCapture: true,
      backgroundChargingOnly: false,
      memoryWarningPct: 30,
      memoryCriticalPct: 12,
      storageWarningPct: 20,
      storageCriticalPct: 8,
      batteryTempWarningCelsius: 38,
      batteryTempCriticalCelsius: 44,
    );
    await store.save(changed);
    final loaded = await store.load();
    expect(loaded.toMap(), changed.toMap());
  });

  test('config corrupto degrada a defaults sin crash', () async {
    await File(
      '${tmp.path}/rootcause-config.json',
    ).writeAsString('{esto no es json');
    final config = await ConfigStore(tmp.path).load();
    expect(config.autoRefreshMinutes, 5);
  });

  test('migra el archivo de idioma heredado de v0.1.x', () async {
    await File('${tmp.path}/rootcause-language').writeAsString('en');
    final store = ConfigStore(tmp.path);
    final config = await store.load();
    expect(config.spanish, isFalse);

    // Al guardar, el archivo heredado desaparece y manda el config nuevo.
    await store.save(config);
    expect(File('${tmp.path}/rootcause-language').existsSync(), isFalse);
    expect((await store.load()).spanish, isFalse);
  });

  test('los umbrales del config alimentan el motor de reglas', () {
    const config = AppConfig(memoryWarningPct: 30, memoryCriticalPct: 12);
    expect(config.thresholds.memoryWarningRatio, closeTo(0.30, 0.0001));
    expect(config.thresholds.memoryCriticalRatio, closeTo(0.12, 0.0001));
  });
}
