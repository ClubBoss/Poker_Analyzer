import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';

/// Represents the average winrate for a week starting at [weekStart].
class WeekWinrate {
  final DateTime weekStart;
  final double winrate;

  const WeekWinrate(this.weekStart, this.winrate);
}

/// Line chart visualising weekly winrate trends.
class WeeklyWinrateChart extends StatelessWidget {
  final List<WeekWinrate> data;
  final double scale;

  const WeeklyWinrateChart({
    super.key,
    required this.data,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].winrate));
    }
    final step = (data.length / 6).ceil();

    return Container(
      height: responsiveSize(context, 200),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
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
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % step != 0 && index != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = data[index].weekStart;
                  return Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.greenAccent,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
