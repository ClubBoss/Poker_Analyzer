import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../services/training_pack_storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';

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
    if (maxCount == 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Активность по дням недели'),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context)],
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Нет данных за последнюю неделю',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < counts.length; i++) {
      final color = AppColors.accent;
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
    final interval = pow(10, (log(maxCount) / ln10).floor()).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активность по дням недели'),
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
              maxY: maxCount.toDouble(),
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Colors.white24, strokeWidth: 1),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black54,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final c = counts[group.x];
                    return BarTooltipItem('$c попыток', const TextStyle(color: Colors.white));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= counts.length) {
                        return const SizedBox.shrink();
                      }
                      final c = counts[index];
                      return c > 0
                          ? Text('$c',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10))
                          : const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        labels[index],
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
