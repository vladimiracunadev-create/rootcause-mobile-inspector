/// Pestaña Almacenamiento: volumen interno, tarjeta SD/USB y caché propia.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../widgets.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({
    super.key,
    required this.storage,
    required this.strings,
    this.onClearCache,
  });

  final StorageInfo storage;
  final AppStrings strings;
  final VoidCallback? onClearCache;

  @override
  Widget build(BuildContext context) {
    final used = storage.totalBytes - storage.freeBytes;
    return ListView(
      children: [
        SectionCard(
          title: '${strings.storageTitle} — ${strings.volumeInternal}',
          children: [
            LinearProgressIndicator(
              value: (1.0 - storage.freeRatio).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            InfoRow(
              label: strings.storageFree,
              value: formatBytes(storage.freeBytes),
            ),
            InfoRow(
              label: strings.storageUsed,
              value: formatBytes(used < 0 ? 0 : used),
            ),
            InfoRow(
              label: strings.storageTotal,
              value: formatBytes(storage.totalBytes),
            ),
          ],
        ),
        // Volúmenes adicionales (SD/USB): solo si existen. Un teléfono sin
        // tarjeta es el caso normal, no un estado de error.
        if (storage.volumes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              strings.volumesNone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...storage.volumes.map(
            (v) => SectionCard(
              title: v.removable
                  ? '${v.label} (${strings.volumeRemovable})'
                  : v.label,
              children: [
                LinearProgressIndicator(
                  value: (1.0 - v.freeRatio).clamp(0.0, 1.0),
                ),
                const SizedBox(height: 8),
                InfoRow(
                  label: strings.storageFree,
                  value: formatBytes(v.freeBytes),
                ),
                InfoRow(
                  label: strings.storageTotal,
                  value: formatBytes(v.totalBytes),
                ),
              ],
            ),
          ),
        SectionCard(
          title: strings.cacheTitle,
          children: [
            InfoRow(
              label: strings.cacheSize,
              value: formatBytes(storage.appCacheBytes),
            ),
            const SizedBox(height: 4),
            Text(
              strings.cacheNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onClearCache != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.cleaning_services, size: 16),
                  label: Text(strings.cacheClear),
                  onPressed: onClearCache,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
