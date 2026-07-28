/// Generador de PDF mínimo en Dart puro — cero dependencias de pub.dev.
///
/// Suficiente para el informe forense: texto, títulos, viñetas y tablas
/// simples sobre páginas A4, con salto de página automático. Usa las fuentes
/// estándar-14 (Helvetica / Helvetica-Bold), que no se embeben, y codifica el
/// texto en WinAnsi (Latin-1 + puntuación tipográfica). Los glifos fuera de
/// WinAnsi que usa el informe (→, ≥, ≤) se sustituyen por su equivalente ASCII.
///
/// No pretende ser un motor PDF general: es el mínimo honesto para producir un
/// archivo `.pdf` válido y legible sin sacar una dependencia de la nada.
library;

import 'dart:typed_data';

/// Un segmento de texto colocado en una posición X absoluta dentro de la línea
/// (permite columnas alineadas en las tablas pese a la fuente proporcional).
class _Seg {
  const _Seg(this.text, this.x);
  final String text;
  final double x;
}

/// Una línea del documento ya lista para paginar. `size == 0` es un espaciador
/// (solo consume [gapBefore] vertical). Si [chart] no es null, la "línea" es
/// un gráfico vectorial que ocupa su propia altura.
class _Line {
  const _Line(this.segs, this.size, this.bold, this.gapBefore, [this.chart]);
  final List<_Seg> segs;
  final double size;
  final bool bold;
  final double gapBefore;
  final _Chart? chart;
}

/// Gráfico de líneas: cada serie es una lista de valores 0–100; cada color es
/// un RGB (0–1). Se dibuja con operadores de trazo del propio PDF.
class _Chart {
  const _Chart(this.series, this.colors, this.height);
  final List<List<int>> series;
  final List<List<double>> colors;
  final double height;
}

class PdfDocument {
  final List<_Line> _lines = [];

  // Geometría A4 en puntos (1/72"). Margen generoso para lectura cómoda.
  static const double pageWidth = 595;
  static const double pageHeight = 842;
  static const double margin = 50;

  double get _usableWidth => pageWidth - 2 * margin;

  // ---- API de contenido -------------------------------------------------

  void title(String text) => _paragraph(text, 20, true, 6, 0);
  void heading(String text) => _paragraph(text, 14, true, 14, 0);
  void paragraph(String text, {bool bold = false}) =>
      _paragraph(text, 11, bold, 3, 0);

  void bullet(String text) {
    // La viñeta y la sangría de continuación mantienen legible el bloque.
    final wrapped = _wrap(text, _usableWidth - 14, 11);
    for (var i = 0; i < wrapped.length; i++) {
      final prefix = i == 0 ? '• ' : '   ';
      _lines.add(
        _Line(
          [_Seg('$prefix${wrapped[i]}', margin)],
          11,
          false,
          i == 0 ? 3 : 1,
        ),
      );
    }
  }

  void spacer([double height = 8]) =>
      _lines.add(_Line(const [], 0, false, height));

  /// Regla horizontal barata: una fila de guiones ASCII al ancho de página.
  void rule() => _paragraph('-' * 90, 9, false, 6, 0);

  /// Gráfico de líneas (mismas series porcentuales que la app). [series] y
  /// [colors] deben tener la misma longitud; cada valor va de 0 a 100.
  void chart(
    List<List<int>> series,
    List<List<double>> colors, {
    double height = 120,
  }) =>
      _lines.add(_Line(const [], 0, false, 8, _Chart(series, colors, height)));

  /// Tabla simple de columnas de ancho uniforme. La cabecera va en negrita.
  void table(List<String> headers, List<List<String>> rows) {
    final cols = headers.length;
    if (cols == 0) return;
    final colWidth = _usableWidth / cols;
    List<_Seg> segsFor(List<String> cells) => [
      for (var i = 0; i < cells.length && i < cols; i++)
        _Seg(cells[i], margin + i * colWidth),
    ];
    _lines.add(_Line(segsFor(headers), 10, true, 6));
    for (final row in rows) {
      _lines.add(_Line(segsFor(row), 10, false, 2));
    }
  }

  void _paragraph(
    String text,
    double size,
    bool bold,
    double gapBefore,
    double indent,
  ) {
    final wrapped = _wrap(text, _usableWidth - indent, size);
    for (var i = 0; i < wrapped.length; i++) {
      _lines.add(
        _Line(
          [_Seg(wrapped[i], margin + indent)],
          size,
          bold,
          i == 0 ? gapBefore : 1,
        ),
      );
    }
  }

  // ---- Ensamblado del PDF ----------------------------------------------

  /// Serializa el documento a bytes de un PDF 1.4 válido.
  Uint8List build() {
    final pageStreams = _renderPages();
    final out = BytesBuilder();
    void add(String s) => out.add(_ascii(s));

    // Cabecera + comentario binario (marca el archivo como no-ASCII).
    add('%PDF-1.4\n');
    out.add([0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A]);

    final n = pageStreams.length;
    final maxObj = 4 + 2 * n; // 1 catálogo, 2 pages, 3-4 fuentes, luego 2/pág.
    final offsets = List<int>.filled(maxObj + 1, 0);

    void writeObj(int num, List<int> body) {
      offsets[num] = out.length;
      add('$num 0 obj\n');
      out.add(body);
      add('\nendobj\n');
    }

    int contentObj(int i) => 5 + 2 * i;
    int pageObj(int i) => 6 + 2 * i;

    // 1: catálogo.
    writeObj(1, _ascii('<< /Type /Catalog /Pages 2 0 R >>'));

    // 2: árbol de páginas.
    final kids = [for (var i = 0; i < n; i++) '${pageObj(i)} 0 R'].join(' ');
    writeObj(2, _ascii('<< /Type /Pages /Kids [$kids] /Count $n >>'));

    // 3-4: fuentes estándar (no se embeben), codificación WinAnsi.
    writeObj(
      3,
      _ascii(
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
      ),
    );
    writeObj(
      4,
      _ascii(
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
        '/Encoding /WinAnsiEncoding >>',
      ),
    );

    // Por cada página: objeto de contenido (stream) + objeto de página.
    for (var i = 0; i < n; i++) {
      final stream = pageStreams[i];
      final body = BytesBuilder();
      body.add(_ascii('<< /Length ${stream.length} >>\nstream\n'));
      body.add(stream);
      body.add(_ascii('\nendstream'));
      writeObj(contentObj(i), body.toBytes());

      writeObj(
        pageObj(i),
        _ascii(
          '<< /Type /Page /Parent 2 0 R '
          '/MediaBox [0 0 ${pageWidth.toInt()} ${pageHeight.toInt()}] '
          '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
          '/Contents ${contentObj(i)} 0 R >>',
        ),
      );
    }

    // Tabla xref (entradas de 20 bytes exactos, EOL \r\n).
    final xrefStart = out.length;
    final count = maxObj + 1;
    add('xref\n');
    add('0 $count\n');
    add('0000000000 65535 f\r\n');
    for (var num = 1; num <= maxObj; num++) {
      final off = offsets[num].toString().padLeft(10, '0');
      add('$off 00000 n\r\n');
    }
    add('trailer\n');
    add('<< /Size $count /Root 1 0 R >>\n');
    add('startxref\n');
    add('$xrefStart\n');
    add('%%EOF\n');

    return out.toBytes();
  }

  /// Pagina las líneas y devuelve el content-stream (bytes) de cada página.
  List<List<int>> _renderPages() {
    final pages = <List<int>>[];
    var content = BytesBuilder();
    var used = false;
    var y = pageHeight - margin;

    void flush() {
      pages.add(content.toBytes());
      content = BytesBuilder();
      y = pageHeight - margin;
      used = false;
    }

    for (final line in _lines) {
      final chartData = line.chart;
      if (chartData != null) {
        if (used && y - line.gapBefore - chartData.height < margin) flush();
        y -= line.gapBefore;
        final bottom = y - chartData.height;
        content.add(_ascii(_chartOps(chartData, bottom)));
        used = true;
        y = bottom;
        continue;
      }
      if (line.size == 0) {
        y -= line.gapBefore;
        continue;
      }
      final advance = line.size * 1.4;
      // ¿Cabe en la página actual? Si no, y ya hay algo, salta de página.
      if (used && y - line.gapBefore - advance < margin) {
        flush();
      }
      y -= line.gapBefore;
      final baseline = y - line.size;
      for (final seg in line.segs) {
        if (seg.text.isEmpty) continue;
        final font = line.bold ? '/F2' : '/F1';
        content.add(
          _ascii(
            'BT $font ${_fmt(line.size)} Tf '
            '1 0 0 1 ${_fmt(seg.x)} ${_fmt(baseline)} Tm ',
          ),
        );
        content.add(_pdfString(seg.text));
        content.add(_ascii(' Tj ET\n'));
      }
      used = true;
      y -= advance;
    }
    if (used || pages.isEmpty) flush();
    return pages;
  }

  /// Operadores de trazo del gráfico (fuera de BT/ET): rejilla 0/50/100 y una
  /// polilínea por serie, escaladas al ancho útil y a [_Chart.height].
  String _chartOps(_Chart ch, double bottom) {
    final b = StringBuffer();
    final left = margin;
    final width = _usableWidth;
    final height = ch.height;
    // Rejilla gris tenue en 0, 50 y 100 %.
    b.write('0.7 0.7 0.7 RG 0.5 w\n');
    for (final pct in const [0, 50, 100]) {
      final gy = bottom + height * pct / 100;
      b.write(
        '${_fmt(left)} ${_fmt(gy)} m ${_fmt(left + width)} ${_fmt(gy)} l S\n',
      );
    }
    for (var s = 0; s < ch.series.length; s++) {
      final series = ch.series[s];
      if (series.length < 2) continue;
      final c = s < ch.colors.length ? ch.colors[s] : const [0.0, 0.0, 0.0];
      b.write('${_fmt(c[0])} ${_fmt(c[1])} ${_fmt(c[2])} RG 1.5 w\n');
      final step = width / (series.length - 1);
      for (var i = 0; i < series.length; i++) {
        final x = left + step * i;
        final py = bottom + height * series[i].clamp(0, 100) / 100;
        b.write('${_fmt(x)} ${_fmt(py)} ${i == 0 ? 'm' : 'l'}\n');
      }
      b.write('S\n');
    }
    // Restaura color de trazo negro para lo que siga.
    b.write('0 0 0 RG\n');
    return b.toString();
  }

  // ---- Texto: envoltura y codificación ---------------------------------

  /// Ancho estimado (Helvetica es proporcional; 0.52·em es una media segura
  /// que tiende a sub-llenar la línea antes que a desbordarla).
  double _estWidth(String s, double size) => s.length * size * 0.52;

  List<String> _wrap(String text, double maxWidth, double size) {
    final result = <String>[];
    for (final rawLine in text.split('\n')) {
      final words = _breakLongWords(rawLine.split(' '), maxWidth, size);
      var current = '';
      for (final w in words) {
        final candidate = current.isEmpty ? w : '$current $w';
        if (current.isEmpty || _estWidth(candidate, size) <= maxWidth) {
          current = candidate;
        } else {
          result.add(current);
          current = w;
        }
      }
      result.add(current);
    }
    return result.isEmpty ? [''] : result;
  }

  /// Parte tokens que por sí solos no caben (URLs, rutas largas) por carácter.
  List<String> _breakLongWords(List<String> words, double maxWidth, double s) {
    final out = <String>[];
    for (final w in words) {
      if (_estWidth(w, s) <= maxWidth || w.length <= 1) {
        out.add(w);
        continue;
      }
      final maxChars = (maxWidth / (s * 0.52)).floor().clamp(1, w.length);
      for (var i = 0; i < w.length; i += maxChars) {
        out.add(w.substring(i, (i + maxChars).clamp(0, w.length)));
      }
    }
    return out;
  }

  static List<int> _ascii(String s) => s.codeUnits;

  static String _fmt(double v) {
    final r = (v * 100).round() / 100;
    return r == r.truncateToDouble() ? r.toInt().toString() : r.toString();
  }

  /// Sustituciones de glifos fuera de WinAnsi que aparecen en el informe.
  static const Map<int, String> _replacements = {
    0x2192: '->', // →
    0x2190: '<-', // ←
    0x2265: '>=', // ≥
    0x2264: '<=', // ≤
    0x00D7: 'x', // ×
  };

  /// Puntuación tipográfica Unicode que SÍ existe en WinAnsi (0x80-0x9F).
  static const Map<int, int> _winAnsiPunct = {
    0x2018: 0x91, // ‘
    0x2019: 0x92, // ’
    0x201C: 0x93, // “
    0x201D: 0x94, // ”
    0x2013: 0x96, // –
    0x2014: 0x97, // —
    0x2026: 0x85, // …
    0x2022: 0x95, // •
    0x20AC: 0x80, // €
  };

  /// Convierte un String a un literal PDF `( ... )` en bytes WinAnsi, con los
  /// caracteres `(`, `)` y `\` escapados.
  static List<int> _pdfString(String text) {
    final bytes = <int>[0x28]; // '('
    void emit(int b) {
      if (b == 0x28 || b == 0x29 || b == 0x5C) bytes.add(0x5C);
      bytes.add(b);
    }

    for (final rune in text.runes) {
      if ((rune >= 0x20 && rune <= 0x7E) || (rune >= 0xA0 && rune <= 0xFF)) {
        emit(rune); // ASCII imprimible o Latin-1 alto (coincide con WinAnsi)
      } else if (_winAnsiPunct.containsKey(rune)) {
        emit(_winAnsiPunct[rune]!);
      } else if (_replacements.containsKey(rune)) {
        for (final b in _replacements[rune]!.codeUnits) {
          emit(b);
        }
      } else {
        emit(0x3F); // '?' — no representable, pero nunca rompe el PDF
      }
    }
    bytes.add(0x29); // ')'
    return bytes;
  }
}
