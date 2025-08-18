import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_stats_service.dart';
import '../theme/app_colors.dart';
import 'badge_icon.dart';
import 'common/animated_bar_chart.dart';

class StreakChart extends StatelessWidget {
  const StreakChart({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final hands = {for (final e in stats.handsDaily(30)) e.key: e.value};
    final mistakes = {for (final e in stats.mistakesDaily(30)) e.key: e.value};
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final days = [for (var i = 0; i < 30; i++) start.add(Duration(days: i))];
    int maxHands = 0;
    for (final d in days) {
      final count = hands[d] ?? 0;
      if (count > maxHands) maxHands = count;
    }
    if (maxHands == 0) maxHands = 1;
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final count = hands[d] ?? 0;
      final mistakesCount = mistakes[d] ?? 0;
      Color color;
      if (count == 0) {
        color = Colors.grey;
      } else if (mistakesCount > 0) {
        color = Colors.redAccent;
      } else {
        color = Colors.greenAccent;
      }
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              width: 4,
              borderRadius: BorderRadius.circular(2),
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
    final interval = maxHands <= 5 ? 1.0 : (maxHands / 5).ceilToDouble();
    String? message;
    const levels = [3, 7, 14, 30];
    const labels = ['Bronze', 'Silver', 'Gold', 'Platinum'];
    for (var i = 0; i < levels.length; i++) {
      if (stats.currentStreak < levels[i]) {
        final remain = levels[i] - stats.currentStreak;
        message = '$remain days to ${labels[i]}';
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              const BadgeIcon(Icons.local_fire_department, size: 20),
              const SizedBox(width: 8),
              Text(
                'Streak: ${stats.currentStreak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedBarChart(
            data: BarChartData(
              maxY: maxHands.toDouble(),
              minY: 0,
              alignment: BarChartAlignment.spaceBetween,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Colors.white24, strokeWidth: 1),
              ),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: groups,
            ),
          ),
        ),
      ],
    );
  }
}
