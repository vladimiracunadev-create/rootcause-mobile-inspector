/// Sesión de cercanía Bluetooth LE — Dart puro, testeable sin dispositivo.
///
/// El nativo entrega los resultados crudos de cada escaneo manual; aquí se
/// acumulan por dirección y se marca como PERSISTENTE lo que reaparece a lo
/// largo del tiempo — el indicio que interesa a un sensor forense (un
/// dispositivo desconocido que sigue cerca escaneo tras escaneo).
///
/// Honestidad: las direcciones BLE modernas rotan (MAC aleatorizada), así
/// que un mismo aparato puede aparecer como varios; la persistencia es un
/// indicio, no una prueba. Nada de esto se guarda ni se exporta: la sesión
/// vive solo en memoria mientras la app está abierta.
library;

class NearbyDevice {
  const NearbyDevice({
    required this.address,
    required this.name,
    required this.rssi,
    required this.seenScans,
    required this.firstSeenMillis,
    required this.lastSeenMillis,
  });

  final String address;
  final String name;

  /// Último RSSI observado, en dBm (más cercano a 0 = más cerca).
  final int rssi;
  final int seenScans;
  final int firstSeenMillis;
  final int lastSeenMillis;
}

class NearbySession {
  NearbySession({
    this.persistentMinScans = 3,
    this.persistentMinSpan = const Duration(minutes: 10),
  });

  final int persistentMinScans;
  final Duration persistentMinSpan;

  final Map<String, NearbyDevice> _devices = {};
  int _scanCount = 0;

  int get scanCount => _scanCount;

  /// Dispositivos vistos en la sesión, los persistentes primero y luego por
  /// señal más fuerte.
  List<NearbyDevice> get devices {
    final list = _devices.values.toList()
      ..sort((a, b) {
        final p = (isPersistent(b) ? 1 : 0) - (isPersistent(a) ? 1 : 0);
        return p != 0 ? p : b.rssi.compareTo(a.rssi);
      });
    return list;
  }

  bool isPersistent(NearbyDevice d) =>
      d.seenScans >= persistentMinScans &&
      d.lastSeenMillis - d.firstSeenMillis >= persistentMinSpan.inMilliseconds;

  int get persistentCount => _devices.values.where(isPersistent).length;

  /// Registra un escaneo completo. [results] son los mapas crudos del
  /// nativo (`address`, `name`, `rssi`); lo malformado se ignora.
  void recordScan(List<Object?> results, {required int nowMillis}) {
    _scanCount++;
    for (final raw in results) {
      if (raw is! Map) continue;
      final address = raw['address'];
      if (address is! String || address.isEmpty) continue;
      final name = raw['name'] is String && (raw['name'] as String).isNotEmpty
          ? raw['name'] as String
          : '?';
      final rssi = raw['rssi'] is num ? (raw['rssi'] as num).toInt() : 0;
      final previous = _devices[address];
      _devices[address] = NearbyDevice(
        address: address,
        name: name != '?' ? name : previous?.name ?? '?',
        rssi: rssi,
        seenScans: (previous?.seenScans ?? 0) + 1,
        firstSeenMillis: previous?.firstSeenMillis ?? nowMillis,
        lastSeenMillis: nowMillis,
      );
    }
  }

  void clear() {
    _devices.clear();
    _scanCount = 0;
  }
}
