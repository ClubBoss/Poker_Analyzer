import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pack_generation_metrics_tracker_service.dart';
import '../services/autogen_metrics_history_service.dart';
import '../services/autogen_error_stats_logger.dart';
import '../services/autogen_pack_error_classifier_service.dart';
import '../services/file_saver_service.dart';
import '../widgets/autogen_debug_control_panel_widget.dart';
import '../widgets/autogen_event_log_viewer_widget.dart';
import '../widgets/run_comparison_window.dart';
import '../widgets/autogen_error_inspector_widget.dart';
import '../widgets/ab_results_panel_widget.dart';
import '../widgets/auto_format_panel_widget.dart';
import '../widgets/theory_injection_dashboard_panel.dart';

/// Visual dashboard for autogen pack generation metrics.
class AutogenMetricsDashboardScreen extends StatefulWidget {
  static const route = '/autogen_metrics_dashboard';
  const AutogenMetricsDashboardScreen({super.key});

  @override
  State<AutogenMetricsDashboardScreen> createState() =>
      _AutogenMetricsDashboardScreenState();
}

class _AutogenMetricsDashboardScreenState
    extends State<AutogenMetricsDashboardScreen> {
  final PackGenerationMetricsTrackerService _service =
      const PackGenerationMetricsTrackerService();
  final AutogenMetricsHistoryService _historyService =
      const AutogenMetricsHistoryService();
  final AutogenErrorStatsLogger _errorStats = AutogenErrorStatsLogger();
  bool _loading = true;
  Map<String, dynamic> _metrics = const {};
  List<RunMetricsEntry> _history = const [];
  List<RunMetricsEntry> _lastTwoRuns = const [];
  bool _showQuality = true;
  bool _showAcceptance = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    _loadHistory();
  }

  Future<void> _loadMetrics() async {
    final m = await _service.getMetrics();
    if (!mounted) return;
    setState(() {
      _metrics = m;
      _loading = false;
    });
  }

  Future<void> _resetMetrics() async {
    await _service.clearMetrics();
    _errorStats.clear();
    await _loadMetrics();
  }

  Future<void> _exportErrors() async {
    final csv = _errorStats.exportCsv();
    try {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        await FileSaverService.instance.saveCsv('autogen_error_breakdown', csv);
      } else {
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, 'autogen_error_breakdown.csv'));
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(file.path)]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error breakdown exported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export errors: $e')));
      }
    }
  }

  Future<void> _loadHistory() async {
    final h = await _historyService.loadHistory();
    final lastTwo = await _historyService.getLastTwoRuns();
    if (!mounted) return;
    setState(() {
      _history = h;
      _lastTwoRuns = lastTwo;
    });
  }

  double _acceptanceRate() {
    final generated = (_metrics['generatedCount'] as int? ?? 0);
    final rejected = (_metrics['rejectedCount'] as int? ?? 0);
    final total = generated + rejected;
    if (total == 0) return 0;
    return generated / total * 100;
  }

  String _formatLastRun() {
    final ts = _metrics['lastRunTimestamp'] as String? ?? '';
    if (ts.isEmpty) return '-';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return ts;
    }
  }

  Widget _buildTile(String title, String value) {
    return Card(
      child: ListTile(title: Text(title), trailing: Text(value)),
    );
  }

  Widget _buildErrorBreakdown() {
    final counts = _errorStats.counts;
    final entries = AutogenPackErrorType.values
        .map((t) => MapEntry(t, counts[t] ?? 0))
        .where((e) => e.value > 0)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Error Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text('No errors recorded')
            else
              for (final e in entries) Text('• ${e.key.name}: ${e.value}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autogen Metrics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RunComparisonWindow(entries: _lastTwoRuns),
                const SizedBox(height: 16),
                const AutogenDebugControlPanelWidget(),
                const SizedBox(height: 16),
                SizedBox(height: 300, child: AutogenEventLogViewerWidget()),
                const SizedBox(height: 16),
                const AutogenErrorInspectorWidget(),
                const SizedBox(height: 16),
                const ABResultsPanelWidget(),
                const SizedBox(height: 16),
                const AutoFormatPanelWidget(),
                const SizedBox(height: 16),
                Card(
                  child: ExpansionTile(
                    title: const Text('Theory Injection Scheduler'),
                    childrenPadding: const EdgeInsets.all(16),
                    children: const [TheoryInjectionDashboardPanel()],
                  ),
                ),
                const SizedBox(height: 16),
                _buildTile(
                  'Generated',
                  (_metrics['generatedCount'] as int? ?? 0).toString(),
                ),
                _buildTile(
                  'Rejected',
                  (_metrics['rejectedCount'] as int? ?? 0).toString(),
                ),
                _buildTile(
                  'Acceptance Rate',
                  '${_acceptanceRate().toStringAsFixed(1)}%',
                ),
                _buildTile(
                  'Average Quality Score',
                  (_metrics['avgQualityScore'] as num? ?? 0).toStringAsFixed(2),
                ),
                _buildTile('Last Run', _formatLastRun()),
                _buildErrorBreakdown(),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _exportErrors,
                  child: const Text('Export Errors to CSV'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetMetrics,
                  child: const Text('Reset Metrics'),
                ),
                const SizedBox(height: 24),
                _buildChartSection(),
              ],
            ),
    );
  }

  Widget _buildChartSection() {
    if (_history.length < 2) return const SizedBox.shrink();
    final qualitySpots = <FlSpot>[];
    final acceptanceSpots = <FlSpot>[];
    for (var i = 0; i < _history.length; i++) {
      final entry = _history[i];
      qualitySpots.add(FlSpot(i.toDouble(), entry.avgQualityScore * 100));
      acceptanceSpots.add(FlSpot(i.toDouble(), entry.acceptanceRate));
    }
    final lines = <LineChartBarData>[];
    if (_showQuality) {
      lines.add(
        LineChartBarData(
          spots: qualitySpots,
          color: Colors.blueAccent,
          barWidth: 2,
          isCurved: true,
          dotData: const FlDotData(show: false),
        ),
      );
    }
    if (_showAcceptance) {
      lines.add(
        LineChartBarData(
          spots: acceptanceSpots,
          color: Colors.greenAccent,
          barWidth: 2,
          isCurved: true,
          dotData: const FlDotData(show: false),
        ),
      );
    }
    final step = (_history.length / 5).ceil();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    if (touchedSpots.isEmpty) return [];
                    final index = touchedSpots.first.x.toInt();
                    if (index < 0 || index >= _history.length) return [];
                    final entry = _history[index];
                    final d = entry.timestamp;
                    final date =
                        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                    return [
                      LineTooltipItem(
                        '$date\nAcceptance: ${entry.acceptanceRate.toStringAsFixed(1)}%\nQuality: ${(entry.avgQualityScore * 100).toStringAsFixed(1)}%',
                        const TextStyle(color: Colors.white),
                      ),
                    ];
                  },
                ),
              ),
              minY: 0,
              maxY: 100,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, interval: 20),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _history.length) {
                        return const SizedBox.shrink();
                      }
                      if (index % step != 0 && index != _history.length - 1) {
                        return const SizedBox.shrink();
                      }
                      final d = _history[index].timestamp;
                      final label =
                          '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
                      return Text(label, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: 0,
                    y2: 60,
                    color: Colors.red.withOpacity(0.2),
                  ),
                  HorizontalRangeAnnotation(
                    y1: 60,
                    y2: 70,
                    color: Colors.red.withOpacity(0.1),
                  ),
                ],
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.black12),
                  bottom: BorderSide(color: Colors.black12),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 60,
                    color: Colors.red,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      'Low Acceptance Threshold',
                      style: const TextStyle(color: Colors.red),
                      alignment: Alignment.topRight,
                    ),
                  ),
                  HorizontalLine(
                    y: 70,
                    color: Colors.red,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      'Low Quality Threshold',
                      style: const TextStyle(color: Colors.red),
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
              lineBarsData: lines,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceptance Rate'),
                value: _showAcceptance,
                onChanged: (v) => setState(() {
                  _showAcceptance = v ?? true;
                }),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Quality Score'),
                value: _showQuality,
                onChanged: (v) => setState(() {
                  _showQuality = v ?? true;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
