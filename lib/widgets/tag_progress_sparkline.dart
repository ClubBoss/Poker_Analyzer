import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/tag_mastery_history_service.dart';
import '../models/tag_xp_history_entry.dart';

class TagProgressSparkline extends StatelessWidget {
  final String tag;
  final int days;
  const TagProgressSparkline({super.key, required this.tag, this.days = 14});

  static final Map<String, _SparklineData> _cache = {};

  static void clearCache(String tag) => _cache.remove(tag);

  Future<_SparklineData> _load(BuildContext context) async {
    final lower = tag.toLowerCase();
    if (_cache.containsKey(lower)) return _cache[lower]!;
    final service = context.read<TagMasteryHistoryService>();
    final hist = await service.getHistory();
    final list = hist[lower] ?? <TagXpHistoryEntry>[];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final data = List<int>.filled(days, 0);
    for (final e in list) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d.isBefore(start) || d.isAfter(now)) continue;
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) data[idx] += e.xp;
    }
    final result = _SparklineData(start: start, values: data);
    _cache[lower] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SparklineData>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 24, width: 60);
        }
        final data = snapshot.data!;
        final values = data.values;
        final maxVal = values.reduce(math.max);
        final accent = Theme.of(context).colorScheme.secondary;
        final groups = <BarChartGroupData>[];
        for (var i = 0; i < values.length; i++) {
          final v = values[i].toDouble();
          groups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: v,
                  width: 3,
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.7), accent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox(
          height: 24,
          width: values.length * 4,
          child: BarChart(
            BarChartData(
              maxY: maxVal == 0 ? 1 : maxVal.toDouble(),
              minY: 0,
              alignment: BarChartAlignment.spaceBetween,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: groups,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = data.start.add(Duration(days: group.x));
                    final xp = values[group.x.toInt()];
                    final label =
                        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
                    return BarTooltipItem(
                      '$label\n$xp XP',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 300),
            swapAnimationCurve: Curves.easeOut,
          ),
        );
      },
    );
  }
}

class _SparklineData {
  final DateTime start;
  final List<int> values;
  _SparklineData({required this.start, required this.values});
}
