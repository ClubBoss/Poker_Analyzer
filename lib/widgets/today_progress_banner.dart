import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';

class TodayProgressBanner extends StatelessWidget {
  const TodayProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final target = context.watch<DailyTargetService>().target;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final hands = stats.handsPerDay[today] ?? 0;
    final dailyMistakes = stats.mistakesDaily(1);
    final mistakes = dailyMistakes.isNotEmpty ? dailyMistakes.first.value : 0;
    final color = mistakes > 0
        ? Colors.redAccent
        : Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today: $hands/$target hands \u00b7 $mistakes mistakes',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (hands / target).clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
