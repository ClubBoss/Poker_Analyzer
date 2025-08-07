import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/pack_generation_metrics_tracker_service.dart';
import '../services/autogen_metrics_history_service.dart';
import '../widgets/autogen_debug_control_panel_widget.dart';

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
  bool _loading = true;
  Map<String, dynamic> _metrics = const {};
  List<RunMetricsEntry> _history = const [];
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
    await _loadMetrics();
  }

  Future<void> _loadHistory() async {
    final h = await _historyService.loadHistory();
    if (!mounted) return;
    setState(() {
      _history = h;
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
      child: ListTile(
        title: Text(title),
        trailing: Text(value),
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
                const AutogenDebugControlPanelWidget(),
                const SizedBox(height: 16),
                _buildTile('Generated',
                    (_metrics['generatedCount'] as int? ?? 0).toString()),
                _buildTile('Rejected',
                    (_metrics['rejectedCount'] as int? ?? 0).toString()),
                _buildTile('Acceptance Rate',
                    '${_acceptanceRate().toStringAsFixed(1)}%'),
                _buildTile('Average Quality Score',
                    (_metrics['avgQualityScore'] as num? ?? 0)
                        .toStringAsFixed(2)),
                _buildTile('Last Run', _formatLastRun()),
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
      lines.add(LineChartBarData(
        spots: qualitySpots,
        color: Colors.blueAccent,
        barWidth: 2,
        isCurved: true,
        dotData: const FlDotData(show: false),
      ));
    }
    if (_showAcceptance) {
      lines.add(LineChartBarData(
        spots: acceptanceSpots,
        color: Colors.greenAccent,
        barWidth: 2,
        isCurved: true,
        dotData: const FlDotData(show: false),
      ));
    }
    final step = (_history.length / 5).ceil();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
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
                      return Text(label,
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.black12),
                  bottom: BorderSide(color: Colors.black12),
                ),
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
                title: const Text('Quality'),
                value: _showQuality,
                onChanged: (v) => setState(() {
                  _showQuality = v ?? true;
                }),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceptance %'),
                value: _showAcceptance,
                onChanged: (v) => setState(() {
                  _showAcceptance = v ?? true;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

