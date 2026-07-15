/// RootCause Mobile Inspector — entrada de la app.
///
/// Diagnóstico primero, intervención después. Hermano móvil de
/// rootcause-windows-inspector: misma filosofía, plataformas distintas.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/history_store.dart';
import 'core/models.dart';
import 'core/rule_engine.dart';
import 'core/snapshot_json.dart';
import 'meta.dart';
import 'platform/collectors.dart';
import 'ui/screens.dart';
import 'ui/strings.dart';
import 'ui/theme.dart';

void main() {
  runApp(const RootCauseApp());
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
  static const _engine = RuleEngine();

  HistoryStore? _store;
  Snapshot? _snapshot;
  Verdict? _verdict;
  List<HistoryRow> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final snapshot = await _collectors.collect();
    final verdict = _engine.evaluate(snapshot);

    // Persistir la captura en el historial local (evidencia, no telemetría).
    var history = _history;
    try {
      final dir = await _collectors.documentsPath();
      if (dir != null) {
        _store ??= HistoryStore(dir);
        await _store!.append(SnapshotJson.toJsonLine(snapshot, verdict));
        history = await _store!.recent();
      }
    } on FileSystemException {
      // Sin historial no se bloquea el diagnóstico en vivo.
    }

    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _verdict = verdict;
      _history = history;
      _loading = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.forLanguageCode(
      ui.PlatformDispatcher.instance.locale.languageCode,
    );
    final snapshot = _snapshot;
    final verdict = _verdict;

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RootCause'),
          actions: [
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
              Tab(icon: const Icon(Icons.history), text: strings.tabHistory),
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
                  ),
                  AppsScreen(
                    apps: snapshot.apps,
                    auditSupported: snapshot.device.appsAuditSupported,
                    strings: strings,
                  ),
                  NetworkScreen(network: snapshot.network, strings: strings),
                  StorageScreen(storage: snapshot.storage, strings: strings),
                  DeviceScreen(device: snapshot.device, strings: strings),
                  HistoryScreen(history: _history, strings: strings),
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
