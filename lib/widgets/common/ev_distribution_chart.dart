import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_colors.dart';

class EvDistributionChart extends StatelessWidget {
  final List<double> evs;
  const EvDistributionChart({super.key, required this.evs});

  @override
  Widget build(BuildContext context) {
    if (evs.isEmpty) return const SizedBox.shrink();

    final bins = List<int>.filled(10, 0);
    for (final e in evs) {
      if (e <= -20) {
        bins[0]++;
      } else if (e < -15) {
        bins[1]++;
      } else if (e < -10) {
        bins[2]++;
      } else if (e < -5) {
        bins[3]++;
      } else if (e < 0) {
        bins[4]++;
      } else if (e < 5) {
        bins[5]++;
      } else if (e < 10) {
        bins[6]++;
      } else if (e < 15) {
        bins[7]++;
      } else if (e < 20) {
        bins[8]++;
      } else {
        bins[9]++;
      }
    }

    const labels = [
      '≤-20',
      '-20…-15',
      '-15…-10',
      '-10…-5',
      '-5…0',
      '0…5',
      '5…10',
      '10…15',
      '15…20',
      '≥20'
    ];
    final maxCount = bins.reduce(max);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < bins.length; i++) {
      final color = i < 5 ? Colors.redAccent : Colors.greenAccent;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: bins[i].toDouble(),
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
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        height: 160,
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
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    final text = '${labels[index]} (${bins[index]})';
                    return Transform.rotate(
                      angle: -pi / 2,
                      child: Text(
                        text,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
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
