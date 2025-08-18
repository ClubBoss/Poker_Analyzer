import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/training_result.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive.dart';

class AccuracyDistributionChart extends StatelessWidget {
  final List<TrainingResult> sessions;

  const AccuracyDistributionChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    final labels = ['0-40%', '40-60%', '60-80%', '80-100%'];
    final counts = List<int>.filled(labels.length, 0);
    for (final s in sessions) {
      final a = s.accuracy;
      if (a < 40) {
        counts[0]++;
      } else if (a < 60) {
        counts[1]++;
      } else if (a < 80) {
        counts[2]++;
      } else {
        counts[3]++;
      }
    }

    final maxCount = counts.reduce(max);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < counts.length; i++) {
      const color = Colors.blueGrey;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: counts[i].toDouble(),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.7), color],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    double interval = 1;
    if (maxCount > 5) {
      interval = (maxCount / 5).ceilToDouble();
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
            rotationQuarterTurns: 1,
            maxY: maxCount.toDouble(),
            minY: 0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) =>
                  const FlLine(color: Colors.white24, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Transform.rotate(
                    angle: -pi / 2,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 70,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    final text = '${labels[index]} (${counts[index]})';
                    return Transform.rotate(
                      angle: -pi / 2,
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
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
