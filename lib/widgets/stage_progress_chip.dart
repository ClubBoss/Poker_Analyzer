import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/session_log_service.dart';
import '../screens/stage_session_history_screen.dart';

/// Small chip displaying historical stats for a learning path stage.
class StageProgressChip extends StatelessWidget {
  final String stageId;
  final StageStatsWithHistory stats;

  const StageProgressChip({
    super.key,
    required this.stageId,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final hands = stats.handsPlayed;
    final accuracy = stats.accuracy;
    final text = '$hands рук · ${accuracy.toStringAsFixed(0)}%';
    Widget? chart;
    if (stats.history.length >= 3) {
      final spots = <FlSpot>[];
      for (var i = 0; i < stats.history.length; i++) {
        spots.add(FlSpot(i.toDouble(), stats.history[i].accuracy));
      }
      chart = SizedBox(
        height: 32,
        width: stats.history.length * 8.0,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      );
    }
    return Tooltip(
      message:
          'Средняя точность за всё время: ${accuracy.toStringAsFixed(0)}% ($hands рук)',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StageSessionHistoryScreen(stageId: stageId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              if (chart != null) ...[
                const SizedBox(height: 2),
                chart,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
