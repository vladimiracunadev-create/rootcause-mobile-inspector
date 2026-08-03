import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/baseline_store.dart';
import 'package:rootcause_mobile_inspector/core/config_store.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';
import 'package:rootcause_mobile_inspector/core/rule_engine.dart';
import 'package:rootcause_mobile_inspector/ui/pdf.dart';

AppRisk _app(
  String pkg,
  List<String> dangerous, {
  List<String> granted = const [],
  List<String> flags = const [],
  int rx = -1,
  int tx = -1,
}) => AppRisk.fromMap({
  'packageName': pkg,
  'label': pkg,
  'versionName': '1.0',
  'dangerousPermissions': dangerous,
  'grantedPermissions': granted,
  'specialFlags': flags,
  'rxBytes24h': rx,
  'txBytes24h': tx,
});

void main() {
  group('AppRisk v0.7.0', () {
    test('parsea concedidos, datos y capacidades activas', () {
      final a = _app(
        'com.x',
        ['CAMERA', 'RECORD_AUDIO'],
        granted: ['CAMERA'],
        rx: 1000,
        tx: 500,
      );
      expect(a.grantedPermissions, ['CAMERA']);
      expect(a.dataBytes24h, 1500);
      expect(a.rxBytes24h, 1000);
    });

    test('datos negativos degradan a -1 (no disponible)', () {
      final a = _app('com.x', const []);
      expect(a.dataBytes24h, -1);
    });

    test('capacidades activas pesan y elevan la severidad', () {
      final a = _app(
        'com.spy',
        const [],
        flags: const [
          'accessibility-service',
          'notification-listener',
          'device-admin-active',
        ],
      );
      // 4 + 3 + 4 = 11 → WARNING (umbral 8), sin ningún permiso peligroso.
      expect(a.riskScore, 11);
      expect(a.severity, Severity.warning);
      expect(a.activeCapabilities.length, 3);
    });
  });

  group('Escalada de permisos (baseline)', () {
    late Directory tmp;
    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('rootcause-perm-test');
    });
    tearDown(() async => tmp.delete(recursive: true));

    test('detecta un permiso peligroso ganado entre capturas', () async {
      final store = BaselineStore(tmp.path);
      final first = await store.diffAndUpdate(
        [
          _app('com.x', ['CAMERA']),
        ],
        nowMillis: 1000,
        auditSupported: true,
      );
      expect(first.isEmpty, isTrue); // primera vez: se inicializa en silencio

      final second = await store.diffAndUpdate(
        [
          _app('com.x', ['CAMERA', 'RECORD_AUDIO']),
        ],
        nowMillis: 2000,
        auditSupported: true,
      );
      expect(second.permissionGains.length, 1);
      expect(second.permissionGains.first.app.packageName, 'com.x');
      expect(second.permissionGains.first.gained, ['RECORD_AUDIO']);
    });

    test('una app nueva no cuenta como escalada', () async {
      final store = BaselineStore(tmp.path);
      await store.diffAndUpdate(
        [_app('com.a', const [])],
        nowMillis: 1000,
        auditSupported: true,
      );
      final diff = await store.diffAndUpdate(
        [
          _app('com.a', const []),
          _app('com.b', ['CAMERA']),
        ],
        nowMillis: 2000,
        auditSupported: true,
      );
      expect(diff.newApps.map((a) => a.packageName), ['com.b']);
      expect(diff.permissionGains, isEmpty);
    });
  });

  test('RuleEngine reporta perm-escalation cuando hay ganancias', () {
    final snapshot = Snapshot.fromCollectorMap(const {}, timestampMillis: 0);
    final gains = [
      AppPermGain(app: _app('com.x', ['CAMERA']), gained: ['CAMERA']),
    ];
    final verdict = const RuleEngine().evaluate(snapshot, permGains: gains);
    expect(verdict.findings.any((f) => f.id == 'perm-escalation'), isTrue);
  });

  group('AppConfig.viewMode', () {
    test('por defecto es simple y hace round-trip', () {
      const c = AppConfig(viewMode: 'advanced');
      // v0.8.0: el default pasó de 'normal' a 'simple' — la interfaz que
      // menos abruma a quien instala esto asustado.
      expect(const AppConfig().viewMode, 'simple');
      expect(AppConfig.fromMap(c.toMap()).viewMode, 'advanced');
    });

    test('un modo inválido cae al por defecto', () {
      final c = AppConfig.fromMap({'viewMode': 'xxx'});
      expect(c.viewMode, 'simple');
    });

    test('una config existente conserva su modo tras actualizar', () {
      // Un usuario de v0.7.0 que eligió 'normal' no se despierta en 'simple'.
      expect(AppConfig.fromMap({'viewMode': 'normal'}).viewMode, 'normal');
    });
  });

  test('PDF dibuja el gráfico de tendencia (trazos vectoriales)', () {
    final doc = PdfDocument()
      ..heading('Tendencia')
      ..chart(
        const [
          [10, 20, 30],
          [40, 50, 60],
        ],
        const [
          [0.1, 0.45, 0.85],
          [0.0, 0.6, 0.5],
        ],
      );
    final text = String.fromCharCodes(doc.build());
    // Operadores de trazo del PDF: color RG y stroke S.
    expect(text.contains(' RG'), isTrue);
    expect(text.contains('S\n'), isTrue);
    expect(text.trimRight().endsWith('%%EOF'), isTrue);
  });
}
