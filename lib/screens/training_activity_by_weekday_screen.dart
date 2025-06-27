import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';

class TrainingActivityByWeekdayScreen extends StatelessWidget {
  static const route = '/training/activity/weekdays';
  const TrainingActivityByWeekdayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final packs = context
        .watch<TrainingPackStorageService>()
        .packs
        .where((p) => !p.isBuiltIn);
    final counts = List<int>.filled(7, 0);
    for (final p in packs) {
      for (final r in p.history) {
        counts[r.date.weekday - 1]++;
      }
    }
    final maxCount = counts.reduce(max);
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < counts.length; i++) {
      const color = Colors.orangeAccent;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: counts[i].toDouble(),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }
    double interval = 1;
    if (maxCount > 5) interval = (maxCount / 5).ceilToDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активность по дням недели'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
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
                    FlLine(color: Colors.white24, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Transform.rotate(
                      angle: -pi / 2,
                      child: Text(
                        value.toInt().toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
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
                          style:
                              const TextStyle(color: Colors.white, fontSize: 10),
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
      ),
    );
  }
}
