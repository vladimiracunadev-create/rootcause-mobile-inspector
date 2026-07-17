/// Histórico de Cercanía entre sesiones — Dart puro, OPT-IN.
///
/// Con el histórico activado (apagado por defecto), cada escaneo BLE
/// registra qué direcciones se vieron y en qué DÍAS. Un dispositivo que
/// reaparece en varios días distintos es el indicio que un escaneo de
/// sesión no puede dar: así se comporta un rastreador que te sigue.
///
/// Honestidad intacta: las MAC aleatorizadas fragmentan el rastro (un
/// mismo aparato puede aparecer como varios), tus propios accesorios
/// también persisten, y todo vive en el sandbox — se borra con
/// "Borrar evidencia" o desactivando el histórico.
library;

import 'dart:convert';
import 'dart:io';

class NearbyDayRecord {
  const NearbyDayRecord({
    required this.address,
    required this.name,
    required this.daysSeen,
    required this.lastSeenMillis,
  });

  final String address;
  final String name;

  /// Días distintos (yyyy-mm-dd) en que se vio la dirección.
  final List<String> daysSeen;
  final int lastSeenMillis;
}

class NearbyStore {
  NearbyStore(this.directoryPath, {this.maxDevices = 300});

  final String directoryPath;
  final int maxDevices;

  File get _file => File('$directoryPath/rootcause-nearby.json');

  static String dayKey(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  /// Registra un escaneo (mapas crudos del nativo) y devuelve el estado
  /// actualizado. Con retención acotada: se conservan los [maxDevices]
  /// vistos más recientemente.
  Future<List<NearbyDayRecord>> recordScan(
    List<Object?> results, {
    required int nowMillis,
  }) async {
    try {
      final records = await load();
      final byAddress = {for (final r in records) r.address: r};
      final today = dayKey(nowMillis);

      for (final raw in results) {
        if (raw is! Map) continue;
        final address = raw['address'];
        if (address is! String || address.isEmpty) continue;
        final name = raw['name'] is String && (raw['name'] as String).isNotEmpty
            ? raw['name'] as String
            : byAddress[address]?.name ?? '?';
        final previous = byAddress[address];
        final days = [...?previous?.daysSeen];
        if (!days.contains(today)) days.add(today);
        byAddress[address] = NearbyDayRecord(
          address: address,
          name: name,
          daysSeen: days,
          lastSeenMillis: nowMillis,
        );
      }

      var updated = byAddress.values.toList()
        ..sort((a, b) => b.lastSeenMillis.compareTo(a.lastSeenMillis));
      if (updated.length > maxDevices) {
        updated = updated.sublist(0, maxDevices);
      }
      await _save(updated);
      return updated;
    } on FileSystemException {
      return const [];
    }
  }

  Future<List<NearbyDayRecord>> load() async {
    try {
      final file = _file;
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      final devices = decoded is Map ? decoded['devices'] : null;
      if (devices is! List) return const [];
      return [
        for (final d in devices.whereType<Map>())
          if (d['address'] is String)
            NearbyDayRecord(
              address: d['address'] as String,
              name: d['name'] is String ? d['name'] as String : '?',
              daysSeen: d['daysSeen'] is List
                  ? (d['daysSeen'] as List).whereType<String>().toList()
                  : const [],
              lastSeenMillis: d['lastSeenMillis'] is num
                  ? (d['lastSeenMillis'] as num).toInt()
                  : 0,
            ),
      ];
    } on FormatException {
      return const [];
    } on FileSystemException {
      return const [];
    }
  }

  Future<void> _save(List<NearbyDayRecord> records) async {
    final file = _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'devices': [
          for (final r in records)
            {
              'address': r.address,
              'name': r.name,
              'daysSeen': r.daysSeen,
              'lastSeenMillis': r.lastSeenMillis,
            },
        ],
      }),
      flush: true,
    );
  }

  Future<void> clear() async {
    try {
      final file = _file;
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Nada que borrar.
    }
  }
}
