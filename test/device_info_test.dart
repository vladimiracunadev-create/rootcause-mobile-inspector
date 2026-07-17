import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/models.dart';

void main() {
  group('DeviceInfo — capa del fabricante (vendorSkin)', () {
    test('parsea la capa cuando el nativo la entrega', () {
      final device = DeviceInfo.fromMap(const {
        'manufacturer': 'samsung',
        'model': 'SM-A356E',
        'vendorSkin': 'One UI 8.5',
      });
      expect(device.vendorSkin, 'One UI 8.5');
    });

    test('sin campo (Android puro, iOS, v0.2.0) degrada a vacío', () {
      final device = DeviceInfo.fromMap(const {'manufacturer': 'Google'});
      expect(device.vendorSkin, isEmpty);
    });
  });
}
