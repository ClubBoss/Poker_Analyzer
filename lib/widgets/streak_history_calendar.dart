import 'package:flutter/material.dart';

import '../services/streak_tracker_service.dart';

class StreakHistoryCalendar extends StatelessWidget {
  const StreakHistoryCalendar({super.key});

  Future<Map<DateTime, bool>> _load() {
    return StreakTrackerService.instance.getLast30DaysMap();
  }

  Color _color(bool active) => active ? Colors.greenAccent : Colors.redAccent;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Widget _buildGrid(Map<DateTime, bool> map) {
    final days = map.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (row) {
        return Row(
          children: List.generate(6, (col) {
            final index = row * 6 + col;
            if (index >= days.length) {
              return const SizedBox(width: 12, height: 12);
            }
            final d = days[index];
            final active = map[d] ?? false;
            final today = _isToday(d);
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _color(active),
                borderRadius: BorderRadius.circular(2),
                border: today
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _legendItem(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, color: color),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<DateTime, bool>>(
      future: _load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final map = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGrid(map),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legendItem(Colors.greenAccent, 'Зелёный = активность'),
                  const SizedBox(width: 12),
                  _legendItem(Colors.redAccent, 'Красный = пропуск'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
