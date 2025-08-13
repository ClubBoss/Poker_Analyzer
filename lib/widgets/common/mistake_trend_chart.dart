import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'animated_line_chart.dart';

import 'package:intl/intl.dart';

enum MistakeTrendMode { daily, weekly }

class MistakeTrendChart extends StatelessWidget {
  final Map<String, Map<DateTime, int>> counts;
  final Map<String, Color> colors;
  final ValueChanged<DateTime>? onDayTap;
  final Set<DateTime>? highlights;
  final bool showLegend;
  final MistakeTrendMode mode;

  const MistakeTrendChart({
    super.key,
    required this.counts,
    required this.colors,
    this.onDayTap,
    this.highlights,
    this.showLegend = true,
    this.mode = MistakeTrendMode.daily,
  });

  static Map<String, Map<DateTime, int>> aggregateByWeek(
      Map<String, Map<DateTime, int>> src) {
    DateTime? min;
    DateTime? max;
    for (final m in src.values) {
      for (final d in m.keys) {
        min = min == null || d.isBefore(min) ? d : min;
        max = max == null || d.isAfter(max) ? d : max;
      }
    }
    if (min == null || max == null) return {};
    final start = min.subtract(Duration(days: min.weekday - 1));
    final end = max.subtract(Duration(days: max.weekday - 1));
    final result = {for (final k in src.keys) k: <DateTime, int>{}};
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 7))) {
      for (final k in src.keys) {
        result[k]![d] = 0;
      }
    }
    for (final entry in src.entries) {
      for (final e in entry.value.entries) {
        final w = e.key.subtract(Duration(days: e.key.weekday - 1));
        result[entry.key]![w] = (result[entry.key]![w] ?? 0) + e.value;
      }
    }
    return result;
  }

  int _weekNumber(DateTime d) => int.parse(DateFormat('w').format(d));

  String _weekLabel(DateTime monday) {
    final week = _weekNumber(monday);
    final end = monday.add(const Duration(days: 6));
    final s =
        '${monday.day.toString().padLeft(2, '0')}.${monday.month.toString().padLeft(2, '0')}';
    final e =
        '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}';
    return 'W$week ($s–$e)';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Map<DateTime, int>> data = counts;
    if (mode == MistakeTrendMode.weekly) {
      data = aggregateByWeek(counts);
    }
    final datesSet = <DateTime>{};
    for (final m in data.values) {
      datesSet.addAll(m.keys);
    }
    final dates = datesSet.toList()..sort();
    if (dates.isEmpty ||
        data.values.every((m) => m.values.every((v) => v == 0))) {
      return const Center(
        child: Text(
          'Нет данных для графика',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final values = <String, List<int>>{};
    int maxCount = 0;
    for (final entry in data.entries) {
      final list = <int>[];
      for (final d in dates) {
        final v = entry.value[d] ?? 0;
        list.add(v);
        if (v > maxCount) maxCount = maxCount < v ? v : maxCount;
      }
      values[entry.key] = list;
    }

    final step = (dates.length / 6).ceil();
    double interval = 1;
    if (maxCount > 5) interval = (maxCount / 5).ceilToDouble();

    final lines = <LineChartBarData>[];
    for (final entry in values.entries) {
      final spots = <FlSpot>[];
      for (var i = 0; i < entry.value.length; i++) {
        spots.add(FlSpot(i.toDouble(), entry.value[i].toDouble()));
      }
      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors[entry.key] ?? Colors.redAccent,
          barWidth: 2,
          dotData: FlDotData(
            show: highlights != null,
            checkToShowDot: (spot, bar) {
              final d = dates[spot.x.toInt()];
              return highlights?.contains(d) ?? false;
            },
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 4,
              color: bar.color ?? Colors.redAccent,
              strokeColor: Colors.yellow,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    String tooltipText(int index) {
      final d = dates[index];
      final label = mode == MistakeTrendMode.weekly
          ? _weekLabel(d)
          : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
      final lines = [label];
      for (final entry in values.entries) {
        lines.add('${entry.key}: ${entry.value[index]}');
      }
      return lines.join('\n');
    }

    Widget chart = AnimatedLineChart(
      data: LineChartData(
        minY: 0,
        maxY: maxCount.toDouble(),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent &&
                response?.lineBarSpots != null &&
                response!.lineBarSpots!.isNotEmpty) {
              onDayTap?.call(dates[response.lineBarSpots!.first.spotIndex]);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              final idx = spots.first.spotIndex;
              final text = tooltipText(idx);
              return [
                for (int i = 0; i < spots.length; i++)
                  LineTooltipItem(
                    text,
                    const TextStyle(color: Colors.white, fontSize: 12),
                  )
              ];
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
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                final label = mode == MistakeTrendMode.weekly
                    ? 'W${_weekNumber(d)}'
                    : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
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
        lineBarsData: lines,
      ),
    );

    if (counts.length > 6) {
      chart = Stack(
        children: [
          chart,
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: const Text(
              'Слишком много линий, уберите лишние теги',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final legend = Wrap(
      spacing: 8,
      children: [
        for (final entry in values.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[entry.key] ?? Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                entry.key,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
      ],
    );

    if (!showLegend) {
      return chart;
    }

    return Column(
      children: [
        Expanded(child: chart),
        const SizedBox(height: 4),
        legend,
      ],
    );
  }
}
