import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/training_stats_service.dart';
import '../services/saved_hand_manager_service.dart';
import 'common/animated_line_chart.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

enum EvIcmTrendMode { weekly, monthly }

class EvIcmTrendChart extends StatelessWidget {
  final EvIcmTrendMode mode;
  final List<DateTime> sessionDates;
  const EvIcmTrendChart({
    super.key,
    this.mode = EvIcmTrendMode.weekly,
    this.sessionDates = const [],
  });

  String _format(DateTime d) {
    if (mode == EvIcmTrendMode.monthly) {
      return '${d.month.toString().padLeft(2, '0')}.${d.year % 100}';
    }
    final end = d.add(const Duration(days: 6));
    final s =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    final e =
        '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}';
    return '$s-$e';
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final hands = context.watch<SavedHandManagerService>().hands;
    final ev = mode == EvIcmTrendMode.weekly
        ? stats.evWeekly(hands)
        : stats.evMonthly(hands);
    final icm = mode == EvIcmTrendMode.weekly
        ? stats.icmWeekly(hands)
        : stats.icmMonthly(hands);
    final dates = {...ev.map((e) => e.key), ...icm.map((e) => e.key)}.toList()
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
      final v1 = evMap[d];
      final v2 = icmMap[d];
      if (v1 != null) {
        spotsEv.add(FlSpot(i.toDouble(), v1));
        if (v1 < minY) minY = v1;
        if (v1 > maxY) maxY = v1;
      }
      if (v2 != null) {
        spotsIcm.add(FlSpot(i.toDouble(), v2));
        if (v2 < minY) minY = v2;
        if (v2 > maxY) maxY = v2;
      }
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final interval = (maxY - minY) / 4;
    final step = (dates.length / 6).ceil();
    final verticalLines = <VerticalLine>[];
    for (var i = 0; i < sessionDates.length; i++) {
      final d = sessionDates[i];
      for (var j = 0; j < dates.length; j++) {
        final start = dates[j];
        final end = j == dates.length - 1
            ? (mode == EvIcmTrendMode.weekly
                ? start.add(const Duration(days: 7))
                : DateTime(start.year, start.month + 1))
            : dates[j + 1];
        if (!d.isBefore(start) && d.isBefore(end)) {
          verticalLines.add(
            VerticalLine(
              x: j.toDouble(),
              color: Colors.white24,
              dashArray: [2, 2],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topCenter,
                style: const TextStyle(color: Colors.white70, fontSize: 8),
                labelResolver: (_) => '${i + 1}',
              ),
            ),
          );
          break;
        }
      }
    }
    final chart = AnimatedLineChart(
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
                if (i < 0 || i >= dates.length) return const SizedBox.shrink();
                if (i % step != 0 && i != dates.length - 1) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _format(dates[i]),
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
        extraLinesData: ExtraLinesData(verticalLines: verticalLines),
      ),
    );
    return Column(
      children: [
        SizedBox(height: responsiveSize(context, 200), child: chart),
        const SizedBox(height: 4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: AppColors.evPre, text: 'EV'),
            SizedBox(width: 8),
            _Legend(color: AppColors.icmPre, text: 'ICM'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
