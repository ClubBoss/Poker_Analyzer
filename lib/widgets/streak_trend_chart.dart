import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'common/animated_line_chart.dart';

import '../services/streak_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class StreakTrendChart extends StatelessWidget {
  const StreakTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreakService>().history;
    if (data.length < 2) {
      return SizedBox(height: responsiveSize(context, 200));
    }
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].value.toDouble()),
    ];
    final maxY = data
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();
    final step = (data.length / 6).ceil();
    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedLineChart(
        data: LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
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
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != data.length - 1)
                    return const SizedBox.shrink();
                  final d = data[i].key;
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
              spots: spots,
              color: Colors.greenAccent,
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
