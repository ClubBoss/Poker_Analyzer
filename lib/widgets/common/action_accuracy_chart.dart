import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'animated_line_chart.dart';

import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';
import '../../models/v2/training_action.dart';

class ActionAccuracyChart extends StatelessWidget {
  final List<TrainingAction> actions;

  const ActionAccuracyChart({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.length < 2) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];
    int correct = 0;
    for (var i = 0; i < actions.length; i++) {
      if (actions[i].isCorrect) correct++;
      final acc = correct * 100 / (i + 1);
      spots.add(FlSpot(i.toDouble(), acc));
    }
    final step = (actions.length / 6).ceil();
    final line = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Theme.of(context).colorScheme.secondary,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: responsiveSize(context, 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedLineChart(
          data: LineChartData(
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) =>
                  const FlLine(color: Colors.white24, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= actions.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % step != 0 && index != actions.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.white24),
                bottom: BorderSide(color: Colors.white24),
              ),
            ),
            lineBarsData: [line],
          ),
        ),
      ),
    );
  }
}
