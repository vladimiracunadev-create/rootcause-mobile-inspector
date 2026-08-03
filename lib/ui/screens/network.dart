/// Pestaña Red: transporte activo, VPN, red medida y tráfico acumulado.
library;

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../widgets.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({
    super.key,
    required this.network,
    required this.strings,
  });

  final NetworkStatus network;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    String yesNo(bool v) => v ? strings.yes : strings.no;
    return ListView(
      children: [
        SectionCard(
          title: strings.networkTitle,
          children: [
            InfoRow(
              label: strings.netConnected,
              value: yesNo(network.connected),
            ),
            InfoRow(label: strings.netTransport, value: network.transport),
            InfoRow(label: strings.netVpn, value: yesNo(network.vpnActive)),
            InfoRow(label: strings.netMetered, value: yesNo(network.metered)),
            InfoRow(
              label: strings.netDown,
              value: '${network.downstreamKbps} kbps',
            ),
            InfoRow(
              label: strings.netUp,
              value: '${network.upstreamKbps} kbps',
            ),
          ],
        ),
        SectionCard(
          title: strings.netTrafficTitle,
          children: [
            InfoRow(
              label: strings.netRx,
              value: formatBytes(network.totalRxBytes),
            ),
            InfoRow(
              label: strings.netTx,
              value: formatBytes(network.totalTxBytes),
            ),
            const SizedBox(height: 4),
            Text(
              strings.netTrafficNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
