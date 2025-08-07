import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/pack_generation_metrics_tracker_service.dart';

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
  bool _loading = true;
  Map<String, dynamic> _metrics = const {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
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
              ],
            ),
    );
  }
}

