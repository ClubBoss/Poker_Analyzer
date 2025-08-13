import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/training_result.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';

class SessionAccuracyBarChart extends StatelessWidget {
  final List<TrainingResult> sessions;

  const SessionAccuracyBarChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = sessions.where((s) => s.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < recent.length; i++) {
      final r = recent[i];
      final color =
          Color.lerp(Colors.red, Colors.green, r.accuracy.clamp(0, 100) / 100)!;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: r.accuracy,
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.7), color],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: responsiveSize(context, 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: BarChart(
          BarChartData(
            maxY: 100,
            minY: 0,
            alignment: BarChartAlignment.spaceBetween,
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
                    if (index < 0 || index >= recent.length) {
                      return const SizedBox.shrink();
                    }
                    final d = recent[index].date;
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
            barGroups: groups,
          ),
        ),
      ),
    );
  }
}
