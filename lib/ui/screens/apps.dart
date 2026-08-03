/// Pestañas Apps y Señaladas: auditoría por app — Android.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({
    super.key,
    required this.apps,
    required this.auditSupported,
    required this.strings,
    this.usageAccessGranted = false,
    this.onOpenApp,
    this.onGrantUsageAccess,
  });

  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;

  /// `true` cuando el usuario concedió el acceso de uso: las apps
  /// muestran tiempo en pantalla y la lista se ordena por uso real.
  final bool usageAccessGranted;

  /// Abre la ficha de sistema de la app (ahí se desinstala o se revocan
  /// permisos — la intervención real que el SO sí permite).
  final void Function(String packageName)? onOpenApp;

  /// Abre la pantalla del sistema donde se concede el acceso de uso.
  final VoidCallback? onGrantUsageAccess;

  @override
  Widget build(BuildContext context) {
    if (!auditSupported) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(strings.appsUnsupported),
      );
    }
    final risky = apps.where((a) => a.severity != Severity.normal).length;
    // Con acceso de uso, lo que más consume va primero: la respuesta a
    // "¿qué app me está gastando el teléfono?" queda arriba. Sin él, orden
    // alfabético: encontrar una app por su nombre no debería ser una búsqueda.
    final ordered = usageAccessGranted
        ? (apps.toList()..sort(
            (a, b) => b.foregroundMillis24h.compareTo(a.foregroundMillis24h),
          ))
        : (apps.toList()..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          ));
    return ListView(
      children: [
        SectionCard(
          title: strings.appsTitle,
          children: [
            InfoRow(label: strings.appsTotal, value: apps.length.toString()),
            InfoRow(label: strings.appsRiskyCount, value: risky.toString()),
            const SizedBox(height: 4),
            Text(
              strings.appsHonestyNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!usageAccessGranted && onGrantUsageAccess != null) ...[
              const SizedBox(height: 4),
              Text(
                strings.appsUsageNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.timelapse, size: 16),
                  label: Text(strings.appsUsageGrant),
                  onPressed: onGrantUsageAccess,
                ),
              ),
            ],
          ],
        ),
        ...ordered.map(
          (app) => AppCard(app: app, strings: strings, onOpenApp: onOpenApp),
        ),
      ],
    );
  }
}

/// Tarjeta de una app auditada, reutilizada por [AppsScreen] y
/// [FlaggedAppsScreen]. Muestra los permisos en lenguaje humano (no las
/// constantes de Android) — pensado para que alguien sin formación técnica
/// entienda qué está pidiendo cada app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.app,
    required this.strings,
    this.onOpenApp,
  });

  final AppRisk app;
  final AppStrings strings;
  final void Function(String packageName)? onOpenApp;

  /// Decodifica el ícono Base64 una sola vez por construcción; null si viene
  /// vacío o corrupto (la tarjeta cae a un ícono genérico).
  Uint8List? _decodeIcon() {
    if (app.iconBase64.isEmpty) return null;
    try {
      return base64Decode(app.iconBase64);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Las capacidades ACTIVAS (accesibilidad, notificaciones, admin) son el
    // vector de espionaje: se muestran primero y en rojo, no mezcladas.
    final activeFlags = app.activeCapabilities;
    final otherFlags = app.specialFlags
        .where((f) => !activeFlags.contains(f))
        .toList();
    final granted = app.grantedPermissions.toSet();
    final requestedOnly = app.dangerousPermissions
        .where((p) => !granted.contains(p))
        .toList();
    final icon = _decodeIcon();

    return MergeSemantics(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          icon,
                          width: 36,
                          height: 36,
                          gaplessPlayback: true,
                          semanticLabel: app.label,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.android, size: 36),
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.android, size: 36),
                    ),
                  SeverityDot(severity: app.severity),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      app.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    strings.appRiskScore(app.riskScore),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Text(app.packageName, style: theme.textTheme.bodySmall),
              if (app.foregroundMillis24h >= 0)
                Text(
                  strings.appUsage(formatUptime(app.foregroundMillis24h)),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (app.dataBytes24h >= 0)
                Text(
                  strings.appDataUsage(formatBytes(app.dataBytes24h)),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              // Capacidades activas: lo más importante, arriba y en rojo.
              if (activeFlags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  strings.appActiveCapsTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityColor(Severity.critical),
                  ),
                ),
                const SizedBox(height: 2),
                ...activeFlags.map(
                  (f) => _bulletLine(
                    strings.flagLabel(f),
                    color: severityColor(Severity.critical),
                    bold: true,
                  ),
                ),
              ],
              if (app.dangerousPermissions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  strings.appPermsTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                // Concedidos ahora (más relevantes) primero, resaltados.
                ...app.grantedPermissions.map(
                  (p) => _bulletLine(
                    '${strings.permissionLabel(p)} · ${strings.appPermGranted}',
                    color: theme.colorScheme.primary,
                    bold: true,
                  ),
                ),
                // Pedidos pero no concedidos: informativos, atenuados.
                ...requestedOnly.map(
                  (p) => _bulletLine(
                    '${strings.permissionLabel(p)} · ${strings.appPermRequestedOnly}',
                    color: theme.disabledColor,
                  ),
                ),
              ],
              if (otherFlags.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...otherFlags.map(
                  (f) =>
                      _bulletLine(strings.flagLabel(f), color: theme.hintColor),
                ),
              ],
              if (onOpenApp != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(strings.actionAppDetails),
                    onPressed: () => onOpenApp!(app.packageName),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletLine(String text, {Color? color, bool bold = false}) => Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: TextStyle(fontSize: 13, color: color)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Pestaña "Señaladas": solo las apps con superficie riesgosa o instaladas
/// fuera de la tienda, ordenadas por riesgo. Reencuadra lo que la app ya
/// detecta en una lista corta y accionable — sin fingir que las "bloquea".
class FlaggedAppsScreen extends StatelessWidget {
  const FlaggedAppsScreen({
    super.key,
    required this.apps,
    required this.auditSupported,
    required this.strings,
    this.onOpenApp,
  });

  final List<AppRisk> apps;
  final bool auditSupported;
  final AppStrings strings;
  final void Function(String packageName)? onOpenApp;

  @override
  Widget build(BuildContext context) {
    if (!auditSupported) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(strings.appsUnsupported),
      );
    }
    final flagged = apps.where((a) => a.severity != Severity.normal).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return ListView(
      children: [
        SectionCard(
          title: strings.flaggedTitle,
          children: [
            InfoRow(
              label: strings.appsRiskyCount,
              value: flagged.length.toString(),
            ),
            const SizedBox(height: 4),
            Text(
              strings.flaggedNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (flagged.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(strings.flaggedEmpty),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              strings.flaggedCount(flagged.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...flagged.map(
            (app) => AppCard(app: app, strings: strings, onOpenApp: onOpenApp),
          ),
        ],
      ],
    );
  }
}
