import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/core/sha256.dart';

void main() {
  group('SHA-256 puro (vectores FIPS 180-4)', () {
    test('cadena vacía', () {
      expect(
        sha256Hex(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('"abc"', () {
      expect(
        sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('mensaje de dos bloques (56 bytes)', () {
      expect(
        sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('UTF-8 multibyte (evidencia en español)', () {
      // Determinismo: el mismo texto produce siempre el mismo sello.
      expect(sha256Hex('señal crítica'), sha256Hex('señal crítica'));
      expect(sha256Hex('señal crítica'), isNot(sha256Hex('senal critica')));
    });
  });
}
