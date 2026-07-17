import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/nearby.dart';

void main() {
  group('NearbySession', () {
    test('acumula dispositivos entre escaneos y actualiza lo visto', () {
      final session = NearbySession();
      session.recordScan(const [
        {'address': 'AA:BB', 'name': 'Buds', 'rssi': -40},
        {'address': 'CC:DD', 'name': '', 'rssi': -70},
      ], nowMillis: 0);
      session.recordScan(const [
        {'address': 'AA:BB', 'name': 'Buds', 'rssi': -45},
      ], nowMillis: 60000);

      expect(session.scanCount, 2);
      expect(session.devices, hasLength(2));
      final buds = session.devices.firstWhere((d) => d.address == 'AA:BB');
      expect(buds.seenScans, 2);
      expect(buds.rssi, -45);
    });

    test('persistente = visto en ≥3 escaneos que abarcan ≥10 minutos', () {
      final session = NearbySession();
      for (final (i, minutes) in const [(0, 0), (1, 6), (2, 12)]) {
        session.recordScan(const [
          {'address': 'AA:BB', 'name': 'Tracker?', 'rssi': -60},
        ], nowMillis: minutes * 60000 + i); // i evita timestamps idénticos
      }
      final device = session.devices.single;
      expect(session.isPersistent(device), isTrue);
      expect(session.persistentCount, 1);
    });

    test('3 escaneos en 2 minutos NO son persistencia (falta el lapso)', () {
      final session = NearbySession();
      for (final minutes in const [0, 1, 2]) {
        session.recordScan(const [
          {'address': 'AA:BB', 'name': '', 'rssi': -60},
        ], nowMillis: minutes * 60000);
      }
      expect(session.persistentCount, 0);
    });

    test('resultados malformados del nativo se ignoran sin crash', () {
      final session = NearbySession();
      session.recordScan(const [
        null,
        'no soy un mapa',
        {'sin': 'address'},
        {'address': '', 'rssi': -1},
        {'address': 'AA:BB', 'name': 'OK', 'rssi': -50},
      ], nowMillis: 0);
      expect(session.devices, hasLength(1));
      expect(session.devices.single.name, 'OK');
    });

    test('el nombre conocido no se pierde si un escaneo llega sin nombre', () {
      final session = NearbySession();
      session.recordScan(const [
        {'address': 'AA:BB', 'name': 'Buds', 'rssi': -40},
      ], nowMillis: 0);
      session.recordScan(const [
        {'address': 'AA:BB', 'name': '', 'rssi': -42},
      ], nowMillis: 1000);
      expect(session.devices.single.name, 'Buds');
    });
  });
}
