import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_mastery_history_service.dart';
import '../models/tag_xp_history_entry.dart';

class TagTrainingHeatmap extends StatelessWidget {
  final String tag;
  final int days;
  const TagTrainingHeatmap({super.key, required this.tag, this.days = 60});

  static final Map<String, _HeatmapData> _cache = {};

  static void clearCache(String tag) => _cache.remove(tag.toLowerCase());

  Future<_HeatmapData> _load(BuildContext context) async {
    final lower = tag.toLowerCase();
    if (_cache.containsKey(lower)) return _cache[lower]!;
    final service = context.read<TagMasteryHistoryService>();
    final hist = await service.getHistory();
    final list = hist[lower] ?? <TagXpHistoryEntry>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final values = List<int>.filled(days, 0);
    for (final e in list) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d.isBefore(start) || d.isAfter(today)) continue;
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) values[idx] += e.xp;
    }
    final result = _HeatmapData(start: start, values: values);
    _cache[lower] = result;
    return result;
  }

  Color _color(BuildContext context, int value, int max) {
    if (max <= 0) return Colors.transparent;
    final t = value / max;
    return Color.lerp(Colors.green[100], Colors.green[800], t) ?? Colors.green;
  }

  Widget _buildGrid(_HeatmapData data, BuildContext context) {
    final weeks = (days / 7).ceil();
    final maxVal = data.values.fold<int>(0, (p, e) => e > p ? e : p);
    final cells = List.generate(days, (i) => data.values[i]);
    final first = data.start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int row = 0; row < 7; row++)
          Row(
            children: [
              for (int col = 0; col < weeks; col++)
                Builder(builder: (context) {
                  final idx = col * 7 + row;
                  if (idx >= cells.length) {
                    return const SizedBox(width: 10, height: 10);
                  }
                  final date = first.add(Duration(days: idx));
                  final val = cells[idx];
                  final color = _color(context, val, maxVal);
                  final tooltip =
                      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} - $val XP';
                  return Padding(
                    padding: const EdgeInsets.all(1),
                    child: Tooltip(
                      message: tooltip,
                      child: Container(
                        width: 10,
                        height: 10,
                        color: color,
                      ),
                    ),
                  );
                }),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HeatmapData>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80);
        }
        return _buildGrid(snapshot.data!, context);
      },
    );
  }
}

class _HeatmapData {
  final DateTime start;
  final List<int> values;
  _HeatmapData({required this.start, required this.values});
}
