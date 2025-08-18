import 'package:flutter/material.dart';

class TrainingHeatmap extends StatelessWidget {
  final Map<DateTime, int> dailyXp;
  final int days;
  final bool xpOnly;
  const TrainingHeatmap({
    super.key,
    required this.dailyXp,
    this.days = 90,
    this.xpOnly = false,
  });

  Color _color(BuildContext context, int value, int max) {
    if (value == 0 && xpOnly) return Colors.transparent;
    if (max <= 0) return Colors.transparent;
    final t = value / max;
    return Color.lerp(Colors.green[100], Colors.green[800], t) ?? Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final values = List<int>.filled(days, 0);
    for (final entry in dailyXp.entries) {
      final d = DateTime(entry.key.year, entry.key.month, entry.key.day);
      if (d.isBefore(start) || d.isAfter(today)) continue;
      final idx = d.difference(start).inDays;
      if (idx >= 0 && idx < days) values[idx] += entry.value;
    }
    final maxVal = values.fold<int>(0, (p, e) => e > p ? e : p);
    final weeks = (days / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int row = 0; row < 7; row++)
          Row(
            children: [
              for (int col = 0; col < weeks; col++)
                Builder(
                  builder: (context) {
                    final idx = col * 7 + row;
                    if (idx >= values.length) {
                      return const SizedBox(width: 10, height: 10);
                    }
                    final date = start.add(Duration(days: idx));
                    final val = values[idx];
                    final color = _color(context, val, maxVal);
                    final tooltip =
                        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} - $val XP';
                    return Padding(
                      padding: const EdgeInsets.all(1),
                      child: Tooltip(
                        message: tooltip,
                        child: Container(width: 10, height: 10, color: color),
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}
