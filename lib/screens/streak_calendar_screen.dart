import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_stats_service.dart';
import '../widgets/sync_status_widget.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class StreakCalendarScreen extends StatelessWidget {
  const StreakCalendarScreen({super.key});

  Color _color(int count) {
    if (count >= 10) return Colors.redAccent;
    if (count >= 5) return Colors.yellowAccent;
    if (count >= 1) return Colors.greenAccent;
    return Colors.white10;
  }

  Set<DateTime> _current(Map<DateTime, int> map) {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    final result = <DateTime>{};
    while (map[day] != null && map[day]! > 0) {
      result.add(day);
      day = day.subtract(const Duration(days: 1));
    }
    return result;
  }

  Set<DateTime> _longest(Map<DateTime, int> map) {
    final days =
        map.entries
            .where((e) => e.value > 0)
            .map((e) => DateTime(e.key.year, e.key.month, e.key.day))
            .toList()
          ..sort();
    if (days.isEmpty) return {};
    var best = <DateTime>[days.first];
    var current = <DateTime>[days.first];
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current.add(days[i]);
      } else {
        if (current.length > best.length) best = List.from(current);
        current = [days[i]];
      }
    }
    if (current.length > best.length) best = current;
    return best.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final map = stats.handsPerDay;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 41));
    final days = [for (var i = 0; i < 42; i++) start.add(Duration(days: i))];
    final currentStreak = _current(map);
    final longestStreak = _longest(map);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь тренировок'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 42,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isCompactWidth(context) ? 4 : 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, i) {
          final d = days[i];
          final key = DateTime(d.year, d.month, d.day);
          final count = map[key] ?? 0;
          final borderColor = currentStreak.contains(key)
              ? Colors.greenAccent
              : longestStreak.contains(key)
              ? AppColors.accent
              : Colors.transparent;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color(count),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Text(
              '${d.day}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
