import 'package:flutter/material.dart';

import '../services/streak_tracker_service.dart';

class StreakAnalyticsCard extends StatelessWidget {
  const StreakAnalyticsCard({super.key});

  Future<_CardData> _load(BuildContext context) async {
    final service = StreakTrackerService.instance;
    final current = await service.getCurrentStreak();
    final best = await service.getBestStreak();
    final map = await service.getLast30DaysMap();
    return _CardData(current, best, map);
  }

  Color _color(bool active) => active ? Colors.greenAccent : Colors.grey[800]!;

  Widget _buildGrid(Map<DateTime, bool> map) {
    final start = map.keys.first;
    final days = List<DateTime>.from(map.keys);
    days.sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (row) {
        return Row(
          children: List.generate(6, (col) {
            final index = row * 6 + col;
            if (index >= days.length)
              return const SizedBox(width: 12, height: 12);
            final d = days[index];
            final active = map[d] ?? false;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _color(active),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_CardData>(
      future: _load(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔥 ${data.current} days · 🏆 Record: ${data.best}',
                style: TextStyle(color: accent),
              ),
              const SizedBox(height: 12),
              _buildGrid(data.map),
            ],
          ),
        );
      },
    );
  }
}

class _CardData {
  final int current;
  final int best;
  final Map<DateTime, bool> map;
  _CardData(this.current, this.best, this.map);
}
