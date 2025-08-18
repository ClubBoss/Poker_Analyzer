import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/saved_hand_manager_service.dart';
import 'common/animated_line_chart.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class EvStatsChart extends StatelessWidget {
  final int days;
  const EvStatsChart({super.key, this.days = 30});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now().toLocal();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    final dates = [for (int i = 0; i < days; i++) start.add(Duration(days: i))];
    final map = <DateTime, _DayStat>{};
    for (final h in hands) {
      final d = h.savedAt.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(start) || day.isAfter(dates.last)) continue;
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp == null || gto == null || exp == gto) continue;
      final s = map.putIfAbsent(day, () => _DayStat());
      s.mistakes += 1;
      s.evLoss += h.evLoss ?? 0;
    }
    final spotsLoss = <FlSpot>[];
    final spotsMist = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (var i = 0; i < dates.length; i++) {
      final s = map[dates[i]];
      final loss = s?.evLoss ?? 0;
      final m = (s?.mistakes ?? 0).toDouble();
      spotsLoss.add(FlSpot(i.toDouble(), loss));
      spotsMist.add(FlSpot(i.toDouble(), m));
      if (loss < minY) minY = loss;
      if (loss > maxY) maxY = loss;
      if (m > maxY) maxY = m;
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
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
              spots: spotsLoss,
              color: Colors.redAccent,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spotsMist,
              color: Colors.orangeAccent,
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

class _DayStat {
  double evLoss = 0;
  int mistakes = 0;
}
