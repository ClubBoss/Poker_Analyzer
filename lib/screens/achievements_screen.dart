import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:math' as math;
import '../services/streak_service.dart';
import '../services/training_stats_service.dart';
import '../services/user_action_logger.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    UserActionLogger.instance.log('viewed_achievements');
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>().count;
    final stats = context.watch<TrainingStatsService>();
    final today = stats.mistakesDaily(1);
    final mistakesToday = today.isNotEmpty ? today.first.value : 0;
    final accent = Theme.of(context).colorScheme.secondary;

    final items = [
      _AchievementItem(
        title: '7-day Streak',
        icon: Icons.emoji_events,
        progress: math.min(streak, 7),
        target: 7,
      ),
      _AchievementItem(
        title: '30-day Streak',
        icon: Icons.emoji_events,
        progress: math.min(streak, 30),
        target: 30,
      ),
      _AchievementItem(
        title: 'No Mistakes Today',
        icon: Icons.check_circle,
        progress: mistakesToday == 0 ? 1 : 0,
        target: 1,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final completed = item.progress >= item.target;
          final color = completed ? Colors.white : Colors.white54;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, size: 40, color: accent),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:
                              (item.progress / item.target).clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.progress}/${item.target}',
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!completed)
                  const Text(
                    'Incomplete',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AchievementItem {
  final String title;
  final IconData icon;
  final int progress;
  final int target;
  const _AchievementItem({
    required this.title,
    required this.icon,
    required this.progress,
    required this.target,
  });
}
