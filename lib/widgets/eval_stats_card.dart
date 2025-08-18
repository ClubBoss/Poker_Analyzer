import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'common/animated_line_chart.dart';
import 'package:provider/provider.dart';

import '../services/training_stats_service.dart';

class EvalStatsCard extends StatelessWidget {
  const EvalStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final accent = Theme.of(context).colorScheme.secondary;
    final acc = stats.evalAccuracy * 100;
    final history = stats.evalHistory;
    final spots = <FlSpot>[];
    for (var i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i] * 100));
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accuracy: ${acc.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          if (spots.length > 1)
            SizedBox(
              height: 80,
              child: AnimatedLineChart(
                data: LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: accent,
                      barWidth: 2,
                      isCurved: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 80),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: stats.resetEvalStats,
              child: const Text('Reset statistics'),
            ),
          ),
        ],
      ),
    );
  }
}
