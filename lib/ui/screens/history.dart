/// Pestaña Historial: gráfico de tendencia y comparación A→B con deltas.
library;

import 'package:flutter/material.dart';

import '../../core/history_store.dart';
import '../strings.dart';
import '../widgets.dart';

/// Gráfico de tendencia sin dependencias: dos series porcentuales (RAM
/// disponible y disco libre) sobre las capturas del historial, de la más
/// antigua a la más reciente.
class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.memSeries,
    required this.storageSeries,
    required this.tempSeries,
    required this.memColor,
    required this.storageColor,
    required this.tempColor,
    required this.gridColor,
  });

  final List<int> memSeries;
  final List<int> storageSeries;

  /// Temperatura escalada a 0-100 (0-60 °C); vacía si no hay datos.
  final List<int> tempSeries;
  final Color memColor;
  final Color storageColor;
  final Color tempColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final pct in const [0, 50, 100]) {
      final y = size.height * (1 - pct / 100);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    _polyline(canvas, size, memSeries, memColor);
    _polyline(canvas, size, storageSeries, storageColor);
    _polyline(canvas, size, tempSeries, tempColor);
  }

  void _polyline(Canvas canvas, Size size, List<int> series, Color color) {
    if (series.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final step = size.width / (series.length - 1);
    final path = Path();
    for (var i = 0; i < series.length; i++) {
      final x = step * i;
      final y = size.height * (1 - series[i].clamp(0, 100) / 100);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.memSeries != memSeries || old.storageSeries != storageSeries;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.history,
    required this.strings,
  });

  final List<HistoryRow> history;
  final AppStrings strings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Selección A/B por timestamp (estable aunque llegue una captura nueva).
  int? _selA;
  int? _selB;

  void _toggle(int timestamp) {
    setState(() {
      if (_selA == timestamp) {
        _selA = _selB;
        _selB = null;
      } else if (_selB == timestamp) {
        _selB = null;
      } else if (_selA == null) {
        _selA = timestamp;
      } else if (_selB == null) {
        _selB = timestamp;
      } else {
        _selA = timestamp;
        _selB = null;
      }
    });
  }

  HistoryRow? _rowFor(int? timestamp) {
    if (timestamp == null) return null;
    for (final row in widget.history) {
      if (row.timestampMillis == timestamp) return row;
    }
    return null;
  }

  String _delta(int value) => value >= 0 ? '+$value' : '$value';

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final history = widget.history;
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(strings.historyEmpty),
      );
    }

    final theme = Theme.of(context);
    final memColor = theme.colorScheme.primary;
    final storageColor = theme.colorScheme.tertiary;
    final chronological = history.reversed.toList();

    final a = _rowFor(_selA);
    final b = _rowFor(_selB);
    // A → B siempre en orden temporal, elija como elija el usuario.
    final from = a != null && b != null
        ? (a.timestampMillis <= b.timestampMillis ? a : b)
        : null;
    final to = a != null && b != null
        ? (a.timestampMillis <= b.timestampMillis ? b : a)
        : null;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            strings.historyTitle(history.length),
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (history.length >= 3)
          SectionCard(
            title: strings.trendTitle,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Semantics(
                  label: strings.trendTitle,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      memSeries: [
                        for (final r in chronological) r.memAvailablePct,
                      ],
                      storageSeries: [
                        for (final r in chronological) r.storageFreePct,
                      ],
                      // 0-60 °C escalados al eje 0-100 del gráfico; la
                      // leyenda lo declara. Sin datos (iOS), sin línea.
                      tempSeries: chronological.any((r) => r.batteryTempC >= 0)
                          ? [
                              for (final r in chronological)
                                (r.batteryTempC.clamp(0, 60) * 100 ~/ 60),
                            ]
                          : const [],
                      memColor: memColor,
                      storageColor: storageColor,
                      tempColor: theme.colorScheme.error,
                      gridColor: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _legendDot(memColor, strings.trendMemLegend),
                  _legendDot(storageColor, strings.trendStorageLegend),
                  if (chronological.any((r) => r.batteryTempC >= 0))
                    _legendDot(
                      theme.colorScheme.error,
                      strings.trendTempLegend,
                    ),
                ],
              ),
            ],
          ),
        if (from != null && to != null)
          SectionCard(
            title: strings.compareTitle,
            children: [
              Text(
                '${formatTimestamp(from.timestampMillis)} → '
                '${formatTimestamp(to.timestampMillis)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              InfoRow(
                label: strings.compareMem,
                value:
                    '${from.memAvailablePct} % → ${to.memAvailablePct} % '
                    '(${_delta(to.memAvailablePct - from.memAvailablePct)})',
              ),
              InfoRow(
                label: strings.compareStorage,
                value:
                    '${from.storageFreePct} % → ${to.storageFreePct} % '
                    '(${_delta(to.storageFreePct - from.storageFreePct)})',
              ),
              InfoRow(
                label: strings.compareScore,
                value:
                    '${from.score} → ${to.score} '
                    '(${_delta(to.score - from.score)})',
              ),
              InfoRow(
                label: strings.compareRisky,
                value:
                    '${from.riskyApps} → ${to.riskyApps} '
                    '(${_delta(to.riskyApps - from.riskyApps)})',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(strings.compareClear),
                  onPressed: () => setState(() {
                    _selA = null;
                    _selB = null;
                  }),
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(strings.compareHint, style: theme.textTheme.bodySmall),
          ),
        ...history.map((row) {
          final selected =
              row.timestampMillis == _selA || row.timestampMillis == _selB;
          return Material(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            child: InkWell(
              onTap: () => _toggle(row.timestampMillis),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SeverityDot(severity: row.severity),
                        const SizedBox(width: 8),
                        Text(
                          formatTimestamp(row.timestampMillis),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.verdictScore(row.score),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (selected) ...[
                          const Spacer(),
                          Icon(
                            Icons.compare_arrows,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      strings.historyRow(
                        row.memAvailablePct,
                        row.storageFreePct,
                        row.riskyApps,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
