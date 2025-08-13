import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/training_stats_service.dart';
import '../services/saved_hand_manager_service.dart';
import 'common/animated_line_chart.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class DailyEvIcmChart extends StatelessWidget {
  final int days;
  const DailyEvIcmChart({super.key, this.days = 30});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final hands = context.watch<SavedHandManagerService>().hands;
    final ev = stats.evDaily(hands, days);
    final icm = stats.icmDaily(hands, days);
    final dates = {
      for (final e in ev) e.key,
      for (final e in icm) e.key,
    }.toList()
      ..sort();
    if (dates.length < 2) return SizedBox(height: responsiveSize(context, 200));
    final evMap = {for (final e in ev) e.key: e.value};
    final icmMap = {for (final e in icm) e.key: e.value};
    final spotsEv = <FlSpot>[];
    final spotsIcm = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (var i = 0; i < dates.length; i++) {
      final d = dates[i];
      final evv = evMap[d];
      final icmv = icmMap[d];
      if (evv != null) {
        spotsEv.add(FlSpot(i.toDouble(), evv));
        if (evv < minY) minY = evv;
        if (evv > maxY) maxY = evv;
      }
      if (icmv != null) {
        spotsIcm.add(FlSpot(i.toDouble(), icmv));
        if (icmv < minY) minY = icmv;
        if (icmv > maxY) maxY = icmv;
      }
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final interval = (maxY - minY) / 4;
    final step = (dates.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedLineChart(
        data: LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) =>
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
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= dates.length)
                    return const SizedBox.shrink();
                  if (i % step != 0 && i != dates.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = dates[i];
                  return Text(
                    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}',
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
          lineBarsData: [
            LineChartBarData(
              spots: spotsEv,
              color: AppColors.evPre,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsIcm,
              color: AppColors.icmPre,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
