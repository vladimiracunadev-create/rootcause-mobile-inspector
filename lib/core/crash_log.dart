/// Registro LOCAL de errores — Dart puro (`dart:io`).
///
/// Si la app falla, el error queda en un archivo del sandbox que el
/// usuario puede exportar (backup o pestaña Acerca). Jamás se envía a
/// ninguna parte — sin permiso INTERNET no podría aunque quisiéramos.
/// Habría convertido el diagnóstico del crash de v0.2.0 en dos minutos.
library;

import 'dart:io';

class CrashLog {
  CrashLog(this.directoryPath, {this.maxEntries = 20});

  final String directoryPath;
  final int maxEntries;

  File get _file => File('$directoryPath/rootcause-crashlog.txt');

  /// Registra un error con su stack trace, conservando los últimos
  /// [maxEntries]. Nunca lanza: un fallo del registro no debe tapar el
  /// error original.
  Future<void> record(Object error, StackTrace stack, {String? where}) async {
    try {
      final file = _file;
      await file.parent.create(recursive: true);
      final entry = StringBuffer()
        ..writeln(
          '=== ${DateTime.now().toIso8601String()}'
          '${where != null ? ' · $where' : ''} ===',
        )
        ..writeln(error)
        ..writeln(stack)
        ..writeln();
      await file.writeAsString(
        entry.toString(),
        mode: FileMode.append,
        flush: true,
      );

      final content = await file.readAsString();
      final blocks = content
          .split('=== ')
          .where((b) => b.trim().isNotEmpty)
          .toList();
      if (blocks.length > maxEntries) {
        final kept = blocks.sublist(blocks.length - maxEntries);
        await file.writeAsString('=== ${kept.join('=== ')}', flush: true);
      }
    } on Object {
      // Silencio deliberado: registrar el registro fallido no tiene fin.
    }
  }

  Future<String?> read() async {
    try {
      final file = _file;
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return content.trim().isEmpty ? null : content;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = _file;
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nada que limpiar.
    }
  }
}
