import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class MistakeTrendChart extends StatelessWidget {
  final Map<DateTime, int> counts;

  const MistakeTrendChart({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    if (counts.values.every((v) => v == 0)) {
      return const Center(
        child: Text(
          'Нет данных для графика',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final dates = counts.keys.toList()..sort();
    final values = [for (final d in dates) counts[d] ?? 0];
    final maxCount = values.reduce(max);
    final spots = <FlSpot>[for (var i = 0; i < dates.length; i++) FlSpot(i.toDouble(), values[i].toDouble())];
    final step = (dates.length / 6).ceil();
    double interval = 1;
    if (maxCount > 5) interval = (maxCount / 5).ceilToDouble();

    final line = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.redAccent,
      barWidth: 2,
      dotData: FlDotData(show: false),
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxCount.toDouble(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((s) {
                final d = dates[s.spotIndex];
                final label = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                final count = values[s.spotIndex];
                return LineTooltipItem(
                  '$label: $count',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white24, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                final index = value.toInt();
                if (index < 0 || index >= dates.length) {
                  return const SizedBox.shrink();
                }
                if (index % step != 0 && index != dates.length - 1) {
                  return const SizedBox.shrink();
                }
                final d = dates[index];
                final label = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
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
        lineBarsData: [line],
      ),
    );
  }
}
