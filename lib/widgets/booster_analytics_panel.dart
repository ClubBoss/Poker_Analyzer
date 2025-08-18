import 'package:flutter/material.dart';

import '../models/booster_stats.dart';
import '../models/player_profile.dart';
import '../theme/app_colors.dart';

/// Panel displaying booster usage analytics.
class BoosterAnalyticsPanel extends StatelessWidget {
  final BoosterStats boosterStats;
  final PlayerProfile profile;

  const BoosterAnalyticsPanel({
    super.key,
    required this.boosterStats,
    required this.profile,
  });

  List<Widget> _tagRows(
    BuildContext context,
    List<MapEntry<String, int>> entries,
    int max,
  ) {
    final accent = Theme.of(context).colorScheme.secondary;
    return [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max > 0 ? e.value / max : 0.0,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _streakCalendar(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final cells = <Widget>[];
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 27));
    for (var i = 0; i < 28; i++) {
      final d = start.add(Duration(days: i));
      final last = boosterStats.lastCompleted;
      bool active = false;
      if (last != null) {
        final diff = DateTime(
          last.year,
          last.month,
          last.day,
        ).difference(DateTime(d.year, d.month, d.day)).inDays;
        active = diff >= 0 && diff < boosterStats.streak;
      }
      cells.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: active ? accent : Colors.grey[700],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }
    return Wrap(children: cells);
  }

  @override
  Widget build(BuildContext context) {
    final counts = boosterStats.counts.isNotEmpty
        ? boosterStats.counts
        : profile.boosterCompletions;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final max = top.isNotEmpty ? top.first.value : 1;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text(
                'Booster Analytics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Streak: ${profile.boosterStreak}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'Completed: ${boosterStats.totalCompleted}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          _streakCalendar(context),
          const SizedBox(height: 8),
          ..._tagRows(context, top, max),
        ],
      ),
    );
  }
}
