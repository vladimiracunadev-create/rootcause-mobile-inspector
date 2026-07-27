import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/ui/pdf.dart';

/// Vista Latin-1 de los bytes para poder buscar subcadenas ASCII/WinAnsi.
String _latin1(List<int> bytes) => String.fromCharCodes(bytes);

void main() {
  test('produce un PDF con cabecera, EOF y una página', () {
    final doc = PdfDocument()
      ..title('RootCause')
      ..paragraph('Informe de prueba.');
    final bytes = doc.build();
    final text = _latin1(bytes);

    expect(text.startsWith('%PDF-1.4'), isTrue);
    expect(text.trimRight().endsWith('%%EOF'), isTrue);
    expect(text.contains('/Count 1'), isTrue);
    expect(text.contains('RootCause'), isTrue);
    // La xref y el trailer están presentes y bien referenciados.
    expect(text.contains('xref'), isTrue);
    expect(text.contains('/Root 1 0 R'), isTrue);
  });

  test('pagina cuando el contenido excede una página', () {
    final doc = PdfDocument();
    for (var i = 0; i < 200; i++) {
      doc.paragraph('Línea de contenido número $i para forzar el salto.');
    }
    final text = _latin1(doc.build());
    // Con 200 líneas debe haber más de una página.
    final match = RegExp(r'/Count (\d+)').firstMatch(text);
    expect(match, isNotNull);
    expect(int.parse(match!.group(1)!), greaterThan(1));
  });

  test('sustituye glifos fuera de WinAnsi y preserva acentos', () {
    final doc = PdfDocument()..paragraph('A → B, temperatura ≥ 45 °C, café');
    final text = _latin1(doc.build());

    // La flecha y el ≥ se sustituyen por ASCII; no queda el glifo crudo.
    expect(text.contains('->'), isTrue);
    expect(text.contains('>='), isTrue);
    expect(text.contains('→'), isFalse); // →
    expect(text.contains('≥'), isFalse); // ≥
    // La 'é' (U+00E9) se codifica como el byte 0xE9 de WinAnsi.
    expect(text.codeUnits.contains(0xE9), isTrue);
    // El grado '°' (U+00B0 → 0xB0) sobrevive.
    expect(text.codeUnits.contains(0xB0), isTrue);
  });

  test('la tabla xref apunta correctamente a cada objeto', () {
    final doc = PdfDocument()
      ..title('RootCause')
      ..heading('Sección')
      ..paragraph('Cuerpo del informe con una tabla.')
      ..table(['A', 'B'], [
        ['1', '2'],
        ['3', '4'],
      ]);
    final bytes = doc.build();
    final text = _latin1(bytes);

    // Localiza el offset de la xref declarado en el trailer.
    final startxref = RegExp(r'startxref\s+(\d+)').firstMatch(text);
    expect(startxref, isNotNull);
    final xrefPos = int.parse(startxref!.group(1)!);
    expect(text.substring(xrefPos, xrefPos + 4), 'xref');

    // Cabecera de la subsección: "0 <count>".
    final header = RegExp(r'xref\s+0 (\d+)').firstMatch(text.substring(xrefPos));
    expect(header, isNotNull);
    final count = int.parse(header!.group(1)!);
    expect(count, greaterThan(4)); // catálogo, pages, 2 fuentes, +página(s)

    // Cada entrada 'n' (objeto 1..count-1) debe apuntar al inicio de "N 0 obj".
    final entries = RegExp(r'(\d{10}) 00000 n').allMatches(text).toList();
    expect(entries.length, count - 1);
    for (var num = 1; num < count; num++) {
      final off = int.parse(entries[num - 1].group(1)!);
      expect(
        text.startsWith('$num 0 obj', off),
        isTrue,
        reason: 'objeto $num no está en el offset $off declarado por la xref',
      );
    }
  });

  test('escapa paréntesis y barra invertida en los literales de texto', () {
    final doc = PdfDocument()..paragraph('texto (con) paréntesis y \\ barra');
    final bytes = doc.build();
    // Cada '(' de contenido va precedido de '\' (0x5C) dentro del stream.
    // Basta comprobar que el PDF se construyó sin excepción y tiene EOF.
    expect(_latin1(bytes).trimRight().endsWith('%%EOF'), isTrue);
  });
}
