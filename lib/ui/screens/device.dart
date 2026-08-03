/// Pestaña Dispositivo: hardware, parche de seguridad e indicios de root.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../widgets.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.device, required this.strings});

  final DeviceInfo device;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SectionCard(
        title: strings.deviceTitle,
        children: [
          InfoRow(
            label: strings.deviceManufacturer,
            value: device.manufacturer,
          ),
          InfoRow(label: strings.deviceModel, value: device.model),
          InfoRow(
            label: strings.deviceOs,
            value: device.sdkInt > 0
                ? '${device.osVersion} (API ${device.sdkInt})'
                : device.osVersion,
          ),
          if (device.vendorSkin.isNotEmpty)
            InfoRow(label: strings.deviceSkin, value: device.vendorSkin),
          InfoRow(label: strings.devicePatch, value: device.securityPatch),
          InfoRow(
            label: strings.deviceCores,
            value: device.cpuCores.toString(),
          ),
          InfoRow(
            label: strings.deviceUptime,
            value: formatUptime(device.uptimeMillis),
          ),
        ],
      ),
      SectionCard(
        title: strings.rootTitle,
        children: [
          if (device.rootIndicators.isEmpty)
            Text(strings.rootNone)
          else ...[
            ...device.rootIndicators.map((i) => Text('• $i')),
            const SizedBox(height: 4),
            Text(
              strings.rootNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    ],
  );
}
