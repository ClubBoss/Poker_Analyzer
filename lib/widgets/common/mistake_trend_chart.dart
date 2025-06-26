import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class MistakeTrendChart extends StatelessWidget {
  final Map<String, Map<DateTime, int>> counts;
  final Map<String, Color> colors;
  final ValueChanged<DateTime>? onDayTap;
  final Set<DateTime>? highlights;
  final bool showLegend;

  const MistakeTrendChart({
    super.key,
    required this.counts,
    required this.colors,
    this.onDayTap,
    this.highlights,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    final datesSet = <DateTime>{};
    for (final m in counts.values) {
      datesSet.addAll(m.keys);
    }
    final dates = datesSet.toList()..sort();
    if (dates.isEmpty ||
        counts.values.every((m) => m.values.every((v) => v == 0))) {
      return const Center(
        child: Text(
          'Нет данных для графика',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final values = <String, List<int>>{};
    int maxCount = 0;
    for (final entry in counts.entries) {
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

    String _tooltipText(int index) {
      final d = dates[index];
      final label = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
      final lines = [label];
      for (final entry in values.entries) {
        lines.add('${entry.key}: ${entry.value[index]}');
      }
      return lines.join('\n');
    }

    Widget chart = LineChart(
      LineChartData(
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
              final text = _tooltipText(idx);
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
              FlLine(color: Colors.white24, strokeWidth: 1),
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
                final label =
                    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
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
