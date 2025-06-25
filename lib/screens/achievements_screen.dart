import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/achievement_engine.dart';
import '../services/goal_engine.dart';
import '../theme/app_colors.dart';
import 'goal_editor_screen.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ach = context.watch<AchievementEngine>().achievements;
    final goalsEngine = context.watch<GoalEngine>();
    final goals = goalsEngine.goals;
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalEditorScreen()),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ach.length + goals.length,
        itemBuilder: (context, index) {
          if (index < ach.length) {
            final item = ach[index];
            final unlocked = item.completed;
            final color = unlocked ? Colors.white : Colors.white54;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(item.icon, color: accent),
                title: Text(
                  item.title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(
                  unlocked ? Icons.check_circle : Icons.lock,
                  color: unlocked ? Colors.green : Colors.grey,
                ),
                subtitle: LinearProgressIndicator(
                  value: (item.progress / item.target).clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            );
          }
          final g = goals[index - ach.length];
          final prog = goalsEngine.progress(g);
          final unlocked = prog >= g.target;
          final color = unlocked ? Colors.white : Colors.white54;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(Icons.flag, color: accent),
              title: Text(
                g.title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              trailing: Icon(
                unlocked ? Icons.check_circle : Icons.flag,
                color: unlocked ? Colors.green : Colors.grey,
              ),
              subtitle: LinearProgressIndicator(
                value: (prog / g.target).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          );
        },
      ),
    );
  }
}
