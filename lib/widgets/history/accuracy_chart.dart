import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../common/animated_line_chart.dart';
import '../../models/training_result.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';

class AccuracyChart extends StatelessWidget {
  final List<TrainingResult> sessions;

  const AccuracyChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.length < 2) {
      return const SizedBox.shrink();
    }

    final sortedSessions = [...sessions]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    for (var i = 0; i < sortedSessions.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedSessions[i].accuracy));
    }
    final step = (sortedSessions.length / 6).ceil();

    final barData = LineChartBarData(
      spots: spots,
      color: Colors.greenAccent,
      barWidth: 2,
      isCurved: true,
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
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    if (index < 0 || index >= sortedSessions.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % step != 0 && index != sortedSessions.length - 1) {
                      return const SizedBox.shrink();
                    }
                    final d = sortedSessions[index].date;
                    final label =
                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                    return Text(
                      label,
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
            lineBarsData: [barData],
          ),
        ),
      ),
    );
  }
}
