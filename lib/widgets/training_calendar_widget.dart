import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_stats_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class TrainingCalendarWidget extends StatelessWidget {
  const TrainingCalendarWidget({super.key});

  Color _color(int count) {
    if (count >= 10) return Colors.redAccent;
    if (count >= 5) return Colors.yellowAccent;
    if (count >= 1) return Colors.greenAccent;
    return Colors.white10;
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        itemCount: 42,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isCompactWidth(context) ? 4 : 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, i) {
          final d = days[i];
          final count = map[d] ?? 0;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color(count),
              borderRadius: BorderRadius.circular(4),
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
