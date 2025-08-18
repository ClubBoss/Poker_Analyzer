import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';

class StreakHistoryScreen extends StatelessWidget {
  const StreakHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final target = context.watch<DailyTargetService>().target;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 13));
    final data = <MapEntry<DateTime, int>>[];
    int maxHands = target;
    for (int i = 0; i < 14; i++) {
      final day = start.add(Duration(days: i));
      final count = stats.handsPerDay[day] ?? 0;
      data.add(MapEntry(day, count));
      maxHands = max(maxHands, count);
    }
    double interval = 1;
    if (maxHands > 5) interval = (maxHands / 5).ceilToDouble();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      final count = data[i].value;
      final color = count >= target ? Colors.greenAccent : Colors.blueGrey;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak History'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
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
              maxY: maxHands.toDouble(),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
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
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final d = data[index].key;
                      final label =
                          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                      return Transform.rotate(
                        angle: -pi / 2,
                        child: Text(
                          label,
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
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: target.toDouble(),
                    color: AppColors.accent,
                    strokeWidth: 2,
                    dashArray: [4, 4],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
