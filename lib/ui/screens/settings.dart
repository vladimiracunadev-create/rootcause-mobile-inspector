/// Pestaña Configuración: modo de vista, capturas, umbrales e idioma.
library;

import 'package:flutter/material.dart';

import '../../core/config_store.dart';
import '../../core/models.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.config,
    required this.strings,
    required this.onChanged,
    this.onBackup,
    this.onRestore,
    this.onWipe,
    this.onReport,
  });

  final AppConfig config;
  final AppStrings strings;
  final ValueChanged<AppConfig> onChanged;
  final VoidCallback? onBackup;
  final VoidCallback? onRestore;
  final VoidCallback? onWipe;
  final VoidCallback? onReport;

  /// Fila de umbral con paso de ±1 dentro de [min, max].
  Widget _stepper(
    BuildContext context, {
    required String label,
    required int value,
    required String unit,
    required int min,
    required int max,
    required ValueChanged<int> onValue,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onValue(value - 1) : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value $unit',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onValue(value + 1) : null,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = config;
    return ListView(
      children: [
        SectionCard(
          title: strings.settingsCaptureTitle,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(strings.settingsInterval)),
                DropdownButton<int>(
                  value: c.autoRefreshMinutes,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(strings.settingsIntervalOff),
                    ),
                    for (final m in const [1, 5, 15])
                      DropdownMenuItem(
                        value: m,
                        child: Text(strings.settingsIntervalMinutes(m)),
                      ),
                  ],
                  onChanged: (v) => v == null
                      ? null
                      : onChanged(c.copyWith(autoRefreshMinutes: v)),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsBackground),
              value: c.backgroundCapture,
              onChanged: (v) => onChanged(c.copyWith(backgroundCapture: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsChargingOnly),
              value: c.backgroundChargingOnly,
              onChanged: c.backgroundCapture
                  ? (v) => onChanged(c.copyWith(backgroundChargingOnly: v))
                  : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsNotifyCritical),
              value: c.notifyCritical,
              onChanged: (v) => onChanged(c.copyWith(notifyCritical: v)),
            ),
          ],
        ),
        SectionCard(
          title: strings.settingsThresholdsTitle,
          children: [
            _stepper(
              context,
              label: strings.thresholdMemWarning,
              value: c.memoryWarningPct,
              unit: '%',
              min: c.memoryCriticalPct + 1,
              max: 50,
              onValue: (v) => onChanged(c.copyWith(memoryWarningPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdMemCritical,
              value: c.memoryCriticalPct,
              unit: '%',
              min: 1,
              max: c.memoryWarningPct - 1,
              onValue: (v) => onChanged(c.copyWith(memoryCriticalPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdStorageWarning,
              value: c.storageWarningPct,
              unit: '%',
              min: c.storageCriticalPct + 1,
              max: 50,
              onValue: (v) => onChanged(c.copyWith(storageWarningPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdStorageCritical,
              value: c.storageCriticalPct,
              unit: '%',
              min: 1,
              max: c.storageWarningPct - 1,
              onValue: (v) => onChanged(c.copyWith(storageCriticalPct: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdBatteryWarning,
              value: c.batteryTempWarningCelsius,
              unit: '°C',
              min: 30,
              max: c.batteryTempCriticalCelsius - 1,
              onValue: (v) =>
                  onChanged(c.copyWith(batteryTempWarningCelsius: v)),
            ),
            _stepper(
              context,
              label: strings.thresholdBatteryCritical,
              value: c.batteryTempCriticalCelsius,
              unit: '°C',
              min: c.batteryTempWarningCelsius + 1,
              max: 60,
              onValue: (v) =>
                  onChanged(c.copyWith(batteryTempCriticalCelsius: v)),
            ),
            const SizedBox(height: 4),
            Text(
              strings.settingsThresholdsNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: Text(strings.settingsRestoreDefaults),
                onPressed: () => onChanged(
                  AppConfig(
                    languageCode: c.languageCode,
                    viewMode: c.viewMode,
                    autoRefreshMinutes: c.autoRefreshMinutes,
                    backgroundCapture: c.backgroundCapture,
                    backgroundChargingOnly: c.backgroundChargingOnly,
                    notifyCritical: c.notifyCritical,
                    nearbyHistory: c.nearbyHistory,
                    onboardingSeen: c.onboardingSeen,
                  ),
                ),
              ),
            ),
          ],
        ),
        SectionCard(
          title: strings.tabNearby,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.settingsNearbyHistory),
              value: c.nearbyHistory,
              onChanged: (v) => onChanged(c.copyWith(nearbyHistory: v)),
            ),
          ],
        ),
        if (onBackup != null || onWipe != null)
          SectionCard(
            title: strings.evidenceTitle,
            children: [
              Text(
                strings.evidenceNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              if (onReport != null)
                _evidenceButton(
                  Icons.description_outlined,
                  strings.evidenceReport,
                  onReport,
                ),
              if (onBackup != null)
                _evidenceButton(
                  Icons.archive_outlined,
                  strings.evidenceBackup,
                  onBackup,
                ),
              if (onRestore != null)
                _evidenceButton(
                  Icons.unarchive_outlined,
                  strings.evidenceRestore,
                  onRestore,
                ),
              if (onWipe != null)
                _evidenceButton(
                  Icons.delete_outline,
                  strings.evidenceWipe,
                  onWipe,
                  danger: true,
                ),
            ],
          ),
        SectionCard(
          title: strings.settingsViewModeTitle,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final (mode, label) in [
                  ('simple', strings.viewModeSimple),
                  ('normal', strings.viewModeNormal),
                  ('advanced', strings.viewModeAdvanced),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: c.viewMode == mode,
                    onSelected: (_) => onChanged(c.copyWith(viewMode: mode)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              strings.settingsViewModeNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        SectionCard(
          title: strings.settingsLanguageTitle,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                // "Automático" = seguir el idioma del equipo (languageCode '').
                ChoiceChip(
                  label: Text(strings.settingsLanguageAuto),
                  selected: c.languageCode.isEmpty,
                  onSelected: (_) => onChanged(c.copyWith(languageCode: '')),
                ),
                for (final lang in AppLang.values)
                  ChoiceChip(
                    label: Text(languageNativeName(lang)),
                    selected: c.languageCode == languageCodeOf(lang),
                    onSelected: (_) => onChanged(
                      c.copyWith(languageCode: languageCodeOf(lang)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _evidenceButton(
    IconData icon,
    String label,
    VoidCallback? onPressed, {
    bool danger = false,
  }) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: danger
          ? TextButton.styleFrom(
              foregroundColor: severityColor(Severity.critical),
            )
          : null,
      onPressed: onPressed,
    ),
  );
}
