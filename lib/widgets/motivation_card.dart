import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_goal_engine.dart';
import '../services/achievement_engine.dart';
import '../screens/motivation_screen.dart';
import '../models/user_goal.dart';
import '../models/achievement.dart';

class MotivationCard extends StatelessWidget {
  const MotivationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<UserGoalEngine>().goals;
    final engine = context.watch<UserGoalEngine>();
    UserGoal? bestGoal;
    int goalRemain = 1 << 30;
    for (final g in goals) {
      final remain = g.target - engine.progress(g);
      if (remain > 0 && remain < goalRemain) {
        bestGoal = g;
        goalRemain = remain;
      }
    }

    final achievements = context.watch<AchievementEngine>().achievements;
    Achievement? bestAch;
    int achRemain = 1 << 30;
    for (final a in achievements) {
      final remain = a.nextTarget - a.progress;
      if (remain > 0 && remain < achRemain) {
        bestAch = a;
        achRemain = remain;
      }
    }

    if (bestGoal == null && bestAch == null) {
      return const SizedBox.shrink();
    }

    final showGoal =
        bestGoal != null && (bestAch == null || goalRemain <= achRemain);
    final title = showGoal ? bestGoal.title : bestAch!.title;
    final icon = showGoal ? Icons.flag : bestAch!.icon;
    final progress = showGoal ? engine.progress(bestGoal) : bestAch!.progress;
    final target = showGoal ? bestGoal.target : bestAch!.nextTarget;
    final accent = showGoal
        ? Theme.of(context).colorScheme.secondary
        : bestAch!.level.color;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MotivationScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (progress / target).clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$progress/$target'),
          ],
        ),
      ),
    );
  }
}
