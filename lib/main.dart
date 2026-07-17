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
import 'core/crash_log.dart';
import 'core/history_store.dart';
import 'core/models.dart';
import 'core/nearby.dart';
import 'core/nearby_store.dart';
import 'core/rule_engine.dart';
import 'core/snapshot_json.dart';
import 'meta.dart';
import 'platform/capture_service.dart';
import 'platform/collectors.dart';
import 'platform/evidence_service.dart';
import 'ui/report.dart';
import 'ui/screens.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

void main() {
  // Registro LOCAL de errores no capturados: convierte "se cerró con un
  // error" en un diagnóstico exportable (nunca se envía — sin INTERNET).
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    _recordCrash(details.exception, details.stack ?? StackTrace.current);
    previousOnError?.call(details);
  };
  runZonedGuarded(
    () => runApp(const RootCauseApp()),
    (error, stack) => _recordCrash(error, stack),
  );
}

Future<void> _recordCrash(Object error, StackTrace stack) async {
  try {
    final dir = await const PlatformCollectors().documentsPath();
    if (dir != null) {
      await CrashLog(dir).record(error, stack, where: 'ui');
    }
  } on Object {
    // El registro del error jamás debe generar otro error visible.
  }
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
      if (config.notifyCritical) {
        final strings = AppStrings(config.spanish);
        if (outcome.wentCritical) {
          await collectors.notifyCritical(
            title: strings.alertCriticalTitle,
            body: strings.alertCriticalBody,
          );
        }
        // El caso estrella: una app con superficie de espía instalada
        // mientras el teléfono vigilaba solo. Avisa aunque el veredicto
        // global no sea crítico.
        final risky = outcome.riskyNewApps;
        if (risky.isNotEmpty) {
          await collectors.notifyCritical(
            title: strings.alertNewAppTitle,
            body: strings.alertNewAppBody(
              risky.take(3).map((a) => a.label).join(', '),
            ),
          );
        }
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
  String? _crashLog;

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
        final crash = await CrashLog(dir).read();
        if (mounted) {
          setState(() {
            _config = config;
            _crashLog = crash;
          });
        }
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

  Future<void> _generateReport(AppStrings strings) async {
    final snapshot = _snapshot;
    final verdict = _verdict;
    final dir = _dataDir;
    if (snapshot == null || verdict == null || dir == null) return;
    final chain = await HistoryStore(dir).verifyChain();
    final report = buildForensicReport(
      strings: strings,
      snapshot: snapshot,
      verdict: verdict,
      history: _history,
      chain: chain,
    );
    final file = File('$dir/rootcause-informe-${snapshot.timestampMillis}.md');
    await file.writeAsString(report, flush: true);
    final ok = await _collectors.shareFile(
      path: file.path,
      mimeType: 'text/markdown',
      title: strings.reportShareTitle,
    );
    if (!ok && mounted) _showSnack(strings.shareFailed);
  }

  Future<void> _backup(AppStrings strings) async {
    final dir = _dataDir;
    if (dir == null) return;
    final path = await EvidenceService(
      dir,
    ).writeBackup(nowMillis: DateTime.now().millisecondsSinceEpoch);
    final ok = await _collectors.shareFile(
      path: path,
      mimeType: 'application/json',
      title: strings.evidenceBackup,
    );
    if (!ok && mounted) _showSnack(strings.backupDone(path));
  }

  Future<void> _restore(AppStrings strings) async {
    final dir = _dataDir;
    if (dir == null) return;
    final content = await _collectors.pickAndReadFile();
    if (content == null) return;
    final ok = await EvidenceService(dir).restoreBackup(content);
    if (!mounted) return;
    if (!ok) {
      _showSnack(strings.restoreFail);
      return;
    }
    _showSnack(strings.restoreOk);
    final config = await _configStore?.load();
    if (config != null && mounted) setState(() => _config = config);
    _applyAutoRefresh();
    await _refresh();
  }

  Future<void> _wipe(AppStrings strings) async {
    final dir = _dataDir;
    if (dir == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.wipeConfirmTitle),
        content: Text(strings.wipeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await EvidenceService(dir).wipeEvidence();
    if (!mounted) return;
    _showSnack(strings.wipeDone);
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
    // Con el histórico activado, el escaneo también se persiste por días.
    if (_config.nearbyHistory && _dataDir != null) {
      await NearbyStore(
        _dataDir!,
      ).recordScan(results, nowMillis: DateTime.now().millisecondsSinceEpoch);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _finishOnboarding() async {
    await _updateConfig(_config.copyWith(onboardingSeen: true));
  }

  Future<void> _shareCrashLog(AppStrings strings) async {
    final dir = _dataDir;
    if (dir == null) return;
    final file = File('$dir/rootcause-crashlog.txt');
    if (!await file.exists()) return;
    final ok = await _collectors.shareFile(
      path: file.path,
      mimeType: 'text/plain',
      title: strings.diagShare,
    );
    if (!ok && mounted) _showSnack(strings.shareFailed);
  }

  Future<void> _clearCrashLog() async {
    final dir = _dataDir;
    if (dir == null) return;
    await CrashLog(dir).clear();
    if (mounted) setState(() => _crashLog = null);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(_config.spanish);
    final snapshot = _snapshot;
    final verdict = _verdict;

    // Introducción de primera vez: se muestra una sola vez, antes que nada.
    if (!_loading && !_config.onboardingSeen) {
      return OnboardingScreen(strings: strings, onDone: _finishOnboarding);
    }

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
                    onReport: () => _generateReport(strings),
                    onBackup: () => _backup(strings),
                    onRestore: () => _restore(strings),
                    onWipe: () => _wipe(strings),
                  ),
                  AboutScreen(
                    strings: strings,
                    productName: Meta.productName,
                    version: Meta.version,
                    author: Meta.author,
                    license: Meta.license,
                    repository: Meta.repository,
                    crashLog: _crashLog,
                    onShareCrashLog: _crashLog == null
                        ? null
                        : () => _shareCrashLog(strings),
                    onClearCrashLog: _crashLog == null
                        ? null
                        : () => _clearCrashLog(),
                  ),
                ],
              ),
      ),
    );
  }
}
