/// RootCause Mobile Inspector — entrada de la app.
///
/// Diagnóstico primero, intervención después. Hermano móvil de
/// rootcause-windows-inspector: misma filosofía, plataformas distintas.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config_store.dart';
import 'core/history_store.dart';
import 'core/models.dart';
import 'core/nearby.dart';
import 'core/rule_engine.dart';
import 'core/snapshot_json.dart';
import 'meta.dart';
import 'platform/capture_service.dart';
import 'platform/collectors.dart';
import 'ui/screens.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

void main() {
  runApp(const RootCauseApp());
}

/// Entrada de la captura en segundo plano: la invoca el Worker de Android
/// en un engine Flutter sin UI. Reusa exactamente el mismo núcleo (colector,
/// umbrales configurados, motor de reglas, historial) que la app abierta —
/// una sola política, cero copias divergentes.
@pragma('vm:entry-point')
Future<void> backgroundCapture() async {
  WidgetsFlutterBinding.ensureInitialized();
  const control = MethodChannel('rootcause/background');
  try {
    const collectors = PlatformCollectors();
    final dir = await collectors.documentsPath();
    if (dir != null) {
      final config = await ConfigStore(dir).load();
      final outcome = await const CaptureService(
        collectors,
      ).capture(config: config, directoryPath: dir);
      // La alerta avisa solo en la TRANSICIÓN a crítico, en el idioma
      // configurado. Local de verdad: sin INTERNET no hay push posible.
      if (config.notifyCritical && outcome.wentCritical) {
        final strings = AppStrings(config.spanish);
        await collectors.notifyCritical(
          title: strings.alertCriticalTitle,
          body: strings.alertCriticalBody,
        );
      }
      // El widget del launcher se actualiza también desde el Worker.
      await collectors.refreshWidget();
    }
  } on Exception {
    // Una captura fallida en segundo plano no debe tumbar el Worker.
  } finally {
    try {
      await control.invokeMethod('done');
    } on MissingPluginException {
      // Sin lado nativo (tests): no hay Worker esperando.
    } on PlatformException {
      // El Worker ya terminó por timeout; nada que señalizar.
    }
  }
}

class RootCauseApp extends StatelessWidget {
  const RootCauseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: Meta.productName,
    debugShowCheckedModeBanner: false,
    theme: rootCauseLightTheme(),
    darkTheme: rootCauseDarkTheme(),
    home: const InspectorHome(),
  );
}

class InspectorHome extends StatefulWidget {
  const InspectorHome({super.key});

  @override
  State<InspectorHome> createState() => _InspectorHomeState();
}

class _InspectorHomeState extends State<InspectorHome> {
  static const _collectors = PlatformCollectors();
  static const _captureService = CaptureService(_collectors);

  ConfigStore? _configStore;
  AppConfig _config = const AppConfig();
  String? _dataDir;
  Snapshot? _snapshot;
  Verdict? _verdict;
  List<HistoryRow> _history = const [];
  bool _loading = true;
  Timer? _autoRefresh;

  final NearbySession _nearby = NearbySession();
  NearbyStatus _nearbyStatus = NearbyStatus.idle;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final dir = await _collectors.documentsPath();
      if (dir != null) {
        _dataDir = dir;
        _configStore = ConfigStore(dir);
        final config = await _configStore!.load();
        if (mounted) setState(() => _config = config);
      }
    } on FileSystemException {
      // Sin disco se opera con la configuración por defecto, en memoria.
    }
    _applyAutoRefresh();
    await _refresh();
  }

  void _applyAutoRefresh() {
    _autoRefresh?.cancel();
    final minutes = _config.autoRefreshMinutes;
    if (minutes <= 0) return;
    _autoRefresh = Timer.periodic(Duration(minutes: minutes), (_) {
      if (!_loading) _refresh();
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    // Mismo flujo que el Worker de segundo plano (CaptureService): colecta,
    // baseline de apps, reglas con historial y persistencia — una política.
    final outcome = await _captureService.capture(
      config: _config,
      directoryPath: _dataDir,
    );

    if (!mounted) return;
    setState(() {
      _snapshot = outcome.snapshot;
      _verdict = outcome.verdict;
      _history = outcome.history;
      _loading = false;
    });
    // El widget de pantalla de inicio refleja la captura recién tomada.
    await _collectors.refreshWidget();
  }

  Future<void> _updateConfig(AppConfig next) async {
    final prev = _config;
    setState(() => _config = next);
    await _configStore?.save(next);

    if (next.autoRefreshMinutes != prev.autoRefreshMinutes) {
      _applyAutoRefresh();
    }
    // El permiso de notificaciones se pide al activar lo que las usa
    // (Android 13+); si el usuario lo niega, la alerta simplemente no
    // aparece y el resto sigue funcionando.
    if ((next.backgroundCapture && !prev.backgroundCapture) ||
        (next.notifyCritical && !prev.notifyCritical)) {
      await _collectors.requestNotificationPermissions();
    }
    if (next.backgroundCapture != prev.backgroundCapture ||
        next.backgroundChargingOnly != prev.backgroundChargingOnly) {
      final ok = await _collectors.configureBackgroundCapture(
        enabled: next.backgroundCapture,
        chargingOnly: next.backgroundChargingOnly,
      );
      if (!ok && next.backgroundCapture && mounted) {
        // La plataforma no lo soporta: se revierte y se dice la verdad.
        final reverted = next.copyWith(backgroundCapture: false);
        setState(() => _config = reverted);
        await _configStore?.save(reverted);
        _showSnack(AppStrings(reverted.spanish).settingsBackgroundUnsupported);
        return;
      }
    }

    // Umbrales nuevos: se reevalúa la captura actual sin recapturar. El
    // historial ya contiene esta captura, así que se excluye de la serie.
    final snapshot = _snapshot;
    if (snapshot != null) {
      final prior = _history.length > 1
          ? _history.sublist(1)
          : const <HistoryRow>[];
      setState(() {
        _verdict = RuleEngine(
          thresholds: next.thresholds,
        ).evaluate(snapshot, history: prior);
      });
    }
  }

  Future<void> _toggleLanguage() =>
      _updateConfig(_config.copyWith(spanish: !_config.spanish));

  Future<void> _export(AppStrings strings) async {
    final snapshot = _snapshot;
    final verdict = _verdict;
    if (snapshot == null || verdict == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final json = SnapshotJson.toJson(snapshot, verdict);
    await Clipboard.setData(ClipboardData(text: json));

    var message = strings.exportFail;
    try {
      final dir = await _collectors.documentsPath();
      if (dir != null) {
        final file = File(
          '$dir/rootcause-snapshot-${snapshot.timestampMillis}.json',
        );
        await file.writeAsString(json, flush: true);
        message = strings.exportOk(file.path);
      }
    } on FileSystemException {
      // El JSON ya quedó en el portapapeles; se informa el fallo de archivo.
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSystemScreen(String screen, {String? packageName}) async {
    final ok = await _collectors.openSystemScreen(
      screen,
      packageName: packageName,
    );
    if (!ok && mounted) {
      _showSnack(AppStrings(_config.spanish).actionUnavailable);
    }
  }

  Future<void> _clearOwnCache(AppStrings strings) async {
    final freed = await _collectors.clearOwnCache();
    if (!mounted) return;
    _showSnack(strings.cacheCleared(formatBytes(freed)));
    await _refresh();
  }

  Future<void> _nearbyScan() async {
    setState(() => _nearbyStatus = NearbyStatus.scanning);
    final granted = await _collectors.requestBlePermissions();
    if (!granted) {
      if (mounted) setState(() => _nearbyStatus = NearbyStatus.denied);
      return;
    }
    final results = await _collectors.bleScan(seconds: 15);
    if (!mounted) return;
    if (results == null) {
      setState(() => _nearbyStatus = NearbyStatus.unsupported);
      return;
    }
    setState(() {
      _nearby.recordScan(
        results,
        nowMillis: DateTime.now().millisecondsSinceEpoch,
      );
      _nearbyStatus = NearbyStatus.idle;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_config.spanish);
    final snapshot = _snapshot;
    final verdict = _verdict;

    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RootCause'),
          actions: [
            IconButton(
              icon: const Icon(Icons.translate),
              tooltip: strings.actionLanguage,
              onPressed: _toggleLanguage,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: strings.actionRefresh,
              onPressed: _loading ? null : _refresh,
            ),
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: strings.actionExport,
              onPressed: snapshot == null ? null : () => _export(strings),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: const Icon(Icons.speed), text: strings.tabSummary),
              Tab(icon: const Icon(Icons.apps), text: strings.tabApps),
              Tab(icon: const Icon(Icons.wifi), text: strings.tabNetwork),
              Tab(icon: const Icon(Icons.storage), text: strings.tabStorage),
              Tab(
                icon: const Icon(Icons.phone_android),
                text: strings.tabDevice,
              ),
              Tab(
                icon: const Icon(Icons.bluetooth_searching),
                text: strings.tabNearby,
              ),
              Tab(icon: const Icon(Icons.history), text: strings.tabHistory),
              Tab(icon: const Icon(Icons.settings), text: strings.tabSettings),
              Tab(icon: const Icon(Icons.info_outline), text: strings.tabAbout),
            ],
          ),
        ),
        body: snapshot == null || verdict == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(strings.loading),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  SummaryScreen(
                    snapshot: snapshot,
                    verdict: verdict,
                    strings: strings,
                    onOpenSystemScreen: _openSystemScreen,
                  ),
                  AppsScreen(
                    apps: snapshot.apps,
                    auditSupported: snapshot.device.appsAuditSupported,
                    usageAccessGranted: snapshot.device.usageAccessGranted,
                    strings: strings,
                    onOpenApp: (pkg) =>
                        _openSystemScreen('app-details', packageName: pkg),
                    onGrantUsageAccess: () => _openSystemScreen('usage-access'),
                  ),
                  NetworkScreen(network: snapshot.network, strings: strings),
                  StorageScreen(
                    storage: snapshot.storage,
                    strings: strings,
                    onClearCache: () => _clearOwnCache(strings),
                  ),
                  DeviceScreen(device: snapshot.device, strings: strings),
                  NearbyScreen(
                    session: _nearby,
                    status: _nearbyStatus,
                    strings: strings,
                    onScan: _nearbyScan,
                  ),
                  HistoryScreen(history: _history, strings: strings),
                  SettingsScreen(
                    config: _config,
                    strings: strings,
                    onChanged: _updateConfig,
                  ),
                  AboutScreen(
                    strings: strings,
                    productName: Meta.productName,
                    version: Meta.version,
                    author: Meta.author,
                    license: Meta.license,
                    repository: Meta.repository,
                  ),
                ],
              ),
      ),
    );
  }
}
