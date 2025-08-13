import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/xp_tracker_service.dart';
import '../services/achievement_engine.dart';
import '../services/user_goal_engine.dart';
import '../models/user_goal.dart';
import '../models/achievement.dart';
import '../models/level_stage.dart';
import '../widgets/next_step_card.dart';

class MotivationScreen extends StatelessWidget {
  const MotivationScreen({super.key});

  Widget _goal(UserGoal g, UserGoalEngine engine, Color accent) {
    final progress = engine.progress(g);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (progress / g.target).clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$progress/${g.target}')
        ],
      ),
    );
  }

  Widget _achievement(Achievement a, Color accent) {
    final stage = a.level;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(a.icon, color: stage.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(a.description,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.pct,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(stage.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(stage.label, style: TextStyle(color: stage.color)),
              const SizedBox(height: 4),
              Text('${a.progress}/${a.nextTarget}')
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<XPTrackerService>();
    final engine = context.watch<UserGoalEngine>();
    final goals = engine.goals;
    final achievements = context.watch<AchievementEngine>().achievements;
    final accent = Theme.of(context).colorScheme.secondary;
    final stage = stageForLevel(xp.level);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motivation'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stage.label} Level ${xp.level}',
                  style: TextStyle(
                      color: stage.color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${xp.xp} / ${xp.nextLevelXp} XP',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xp.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(stage.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NextStepCard(),
          const SizedBox(height: 16),
          if (goals.isNotEmpty) ...[
            const Text('Goals', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final g in goals) _goal(g, engine, accent),
            const SizedBox(height: 16),
          ],
          if (achievements.isNotEmpty) ...[
            const Text('Achievements',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final a in achievements) _achievement(a, accent),
          ],
        ],
      ),
    );
  }
}
