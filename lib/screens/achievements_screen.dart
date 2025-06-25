import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/streak_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          final handManager = context.watch<SavedHandManagerService>();
          final eval = context.watch<EvaluationExecutorService>();
          final streak = context.watch<StreakService>().count;
          final goals = context.watch<GoalsService>();

          final summary = eval.summarizeHands(handManager.hands);
          goals.updateAchievements(
            correctHands: summary.correct,
            streakDays: streak,
            goalCompleted: goals.anyCompleted,
          );

          final data = goals.achievements;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final completed = item.completed;
              final color = completed ? Colors.white : Colors.white54;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 32, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (item.progress / item.target).clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.progress}/${item.target}',
                            style: TextStyle(color: color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.check_circle,
                      color: completed ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
