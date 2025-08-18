import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/autogen_real_time_stats_refresher_service.dart';

/// Displays historical autogeneration metrics as a time-series chart.
class AutogenHistoryChartWidget extends StatefulWidget {
  const AutogenHistoryChartWidget({super.key});

  @override
  State<AutogenHistoryChartWidget> createState() =>
      _AutogenHistoryChartWidgetState();
}

class _AutogenHistoryChartWidgetState extends State<AutogenHistoryChartWidget> {
  late final AutogenRealTimeStatsRefresherService _refresher;

  @override
  void initState() {
    super.initState();
    _refresher = AutogenRealTimeStatsRefresherService();
  }

  @override
  void dispose() {
    _refresher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _refresher.notifier,
      builder: (context, _, __) {
        final history = _refresher.history;
        if (history.isEmpty) {
          return const Center(child: Text('No history'));
        }
        history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final maxGenerated = history
            .map((e) => e.generated)
            .fold<int>(0, (a, b) => b > a ? b : a);
        final spotsGenerated = history
            .map(
              (e) => FlSpot(
                e.timestamp.millisecondsSinceEpoch.toDouble(),
                e.generated.toDouble(),
              ),
            )
            .toList();
        final spotsScore = history
            .map(
              (e) => FlSpot(
                e.timestamp.millisecondsSinceEpoch.toDouble(),
                e.avgQualityScore * maxGenerated,
              ),
            )
            .toList();
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxGenerated.toDouble(),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  if (touchedSpots.isEmpty) return [];
                  final index = touchedSpots.first.spotIndex;
                  final entry = history[index];
                  return [
                    LineTooltipItem(
                      '${_formatDate(entry.timestamp)}\nGenerated: ${entry.generated}\nRejected: ${entry.rejected}\nAvgScore: ${entry.avgQualityScore.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white),
                    ),
                  ];
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    if (maxGenerated == 0) return const Text('');
                    final score = value / maxGenerated;
                    return Text(
                      score.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spotsGenerated,
                isCurved: false,
                barWidth: 2,
                color: Colors.blue,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: spotsScore,
                isCurved: true,
                barWidth: 2,
                color: Colors.orange,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}';
}
