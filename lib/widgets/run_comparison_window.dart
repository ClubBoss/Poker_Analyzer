import 'package:flutter/material.dart';

import '../services/autogen_metrics_history_service.dart';

/// Small panel comparing the latest run metrics with the previous run.
class RunComparisonWindow extends StatelessWidget {
  final List<RunMetricsEntry> entries;

  const RunComparisonWindow({super.key, required this.entries});

  String _formatDelta(double value, {bool percent = false, int decimals = 1}) {
    final sign = value >= 0 ? '+' : '-';
    final formatted = value.abs().toStringAsFixed(decimals);
    return percent ? '$sign$formatted%' : '$sign$formatted';
  }

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) return const SizedBox.shrink();
    final last = entries[0];
    final previous = entries[1];
    final acceptanceDelta = last.acceptanceRate - previous.acceptanceRate;
    final qualityDelta = last.avgQualityScore - previous.avgQualityScore;
    final icon = acceptanceDelta >= 0 && qualityDelta >= 0 ? '📈' : '📉';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Δ Acceptance: ${_formatDelta(acceptanceDelta, percent: true)}',
                  style: TextStyle(
                      color: acceptanceDelta > 0
                          ? Colors.green
                          : acceptanceDelta < 0
                              ? Colors.red
                              : Colors.grey),
                ),
                Text(
                  'Δ Quality: ${_formatDelta(qualityDelta, decimals: 2)}',
                  style: TextStyle(
                      color: qualityDelta > 0
                          ? Colors.green
                          : qualityDelta < 0
                              ? Colors.red
                              : Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
