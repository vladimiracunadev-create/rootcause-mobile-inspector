/// Pestaña Cercanía: escaneo Bluetooth LE manual (opt-in).
library;

import 'package:flutter/material.dart';

import '../../core/nearby.dart';
import '../strings.dart';
import '../widgets.dart';

/// Estado del escaneo BLE que la pantalla de Cercanía comunica sin fingir:
/// denegado y no-soportado son estados visibles, no silencios.
enum NearbyStatus { idle, scanning, denied, unsupported }

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({
    super.key,
    required this.session,
    required this.status,
    required this.strings,
    required this.onScan,
  });

  final NearbySession session;
  final NearbyStatus status;
  final AppStrings strings;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final devices = session.devices;
    final persistent = session.persistentCount;
    return ListView(
      children: [
        SectionCard(
          title: strings.nearbyTitle,
          children: [
            Text(strings.nearbyIntro),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: status == NearbyStatus.scanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching, size: 18),
                label: Text(
                  status == NearbyStatus.scanning
                      ? strings.nearbyScanning
                      : strings.nearbyScan(15),
                ),
                onPressed: status == NearbyStatus.scanning ? null : onScan,
              ),
            ),
            if (status == NearbyStatus.denied) ...[
              const SizedBox(height: 8),
              Text(strings.nearbyPermissionDenied),
            ],
            if (status == NearbyStatus.unsupported) ...[
              const SizedBox(height: 8),
              Text(strings.nearbyUnsupported),
            ],
          ],
        ),
        if (session.scanCount > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              strings.nearbySummary(devices.length, session.scanCount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (persistent > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                strings.nearbyPersistentNote(persistent),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ...devices.map(
            (d) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  d.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (session.isPersistent(d)) ...[
                                const SizedBox(width: 8),
                                Text(
                                  strings.nearbyPersistent,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${d.address} · ${strings.nearbySeen(d.seenScans)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text('${d.rssi} dBm'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.nearbyHonestyNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}
