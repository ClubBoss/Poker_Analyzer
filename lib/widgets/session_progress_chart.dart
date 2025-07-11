import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/dynamic_progress_service.dart';
import 'common/animated_line_chart.dart';
import '../theme/app_colors.dart';

class SessionProgressChart extends StatelessWidget {
  final int count;
  const SessionProgressChart({super.key, this.count = 10});

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<DynamicProgressService>().history;
    if (hist.length < 2) return const SizedBox(height: 200);
    final data = hist.length > count ? hist.sublist(hist.length - count) : hist;
    final acc = <FlSpot>[];
    final ev = <FlSpot>[];
    final icm = <FlSpot>[];
    double minY = 0;
    double maxY = 0;
    for (var i = 0; i < data.length; i++) {
      final a = data[i];
      final accVal = a.accuracy * 100;
      acc.add(FlSpot(i.toDouble(), accVal));
      ev.add(FlSpot(i.toDouble(), a.ev));
      icm.add(FlSpot(i.toDouble(), a.icm));
      minY = math.min(minY, math.min(a.ev, a.icm));
      maxY = math.max(maxY, math.max(accVal, math.max(a.ev, a.icm)));
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final interval = (maxY - minY) / 4;
    final step = (data.length / 6).ceil();
    return Container(
      height: 200,
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
                FlLine(color: Colors.white24, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  if (i % step != 0 && i != data.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final d = data[i].date;
                  return Text(
                    '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}',
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
              spots: acc,
              color: Colors.orange,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: ev,
              color: AppColors.evPre,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
            LineChartBarData(
              spots: icm,
              color: AppColors.icmPre,
              barWidth: 2,
              isCurved: false,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
