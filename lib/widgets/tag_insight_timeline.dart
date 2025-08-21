import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/progress_forecast_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class TagInsightTimeline extends StatelessWidget {
  final List<ProgressEntry> series;
  const TagInsightTimeline({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Container(
        height: responsiveSize(context, 200),
        alignment: Alignment.center,
        child: const Text(
          'Недостаточно данных',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    List<ProgressEntry> data = [...series]
      ..sort((a, b) => a.date.compareTo(b.date));
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    data = [
      for (final e in data)
        if (e.date.isAfter(cutoff)) e,
    ];
    if (data.length < 2) {
      data = [...series];
    }
    if (data.length > 20) {
      data = data.sublist(data.length - 20);
    }

    bool weekly = false;
    if (data.length > 1) {
      final diff = data.last.date.difference(data.first.date).inDays;
      if (diff > 40) weekly = true;
    }

    List<MapEntry<DateTime, double>> points;
    if (weekly) {
      final map = <DateTime, List<double>>{};
      for (final e in data) {
        final monday = e.date.subtract(Duration(days: e.date.weekday - 1));
        map.putIfAbsent(monday, () => []).add(e.accuracy);
      }
      points = map.entries
          .map(
            (e) => MapEntry(
              e.key,
              e.value.reduce((a, b) => a + b) / e.value.length,
            ),
          )
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));
    } else {
      points = [for (final e in data) MapEntry(e.date, e.accuracy)];
    }

    if (points.length < 2) {
      return Container(
        height: responsiveSize(context, 200),
        alignment: Alignment.center,
        child: const Text(
          'Недостаточно данных',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final dates = [for (final p in points) p.key];
    final spots = <FlSpot>[];
    double minY = 1;
    double maxY = 0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i].value;
      spots.add(FlSpot(i.toDouble(), a));
      if (a < minY) minY = a;
      if (a > maxY) maxY = a;
    }
    if (minY == maxY) {
      minY -= 0.1;
      maxY += 0.1;
    }
    final interval = ((maxY - minY) / 4).clamp(0.05, 1.0);
    final step = (points.length / 6).ceil();

    final slope = points.last.value - points.first.value;
    final lineColor = slope >= 0 ? Colors.green : Colors.red;

    String label(DateTime d) {
      return weekly
          ? 'W${DateFormat('w').format(d)}'
          : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    }

    return Container(
      height: responsiveSize(context, 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black87,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) {
                return spots.map((s) {
                  final d = dates[s.spotIndex];
                  final value = (s.y * 100).toStringAsFixed(0);
                  return LineTooltipItem(
                    '${label(d)}\n$value%',
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
                  (value * 100).toStringAsFixed(0),
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
                  return Text(
                    label(dates[i]),
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
              color: lineColor,
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
