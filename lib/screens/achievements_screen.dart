import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/achievement_engine.dart';
import '../services/goal_engine.dart';
import '../theme/app_colors.dart';
import 'goal_editor_screen.dart';
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
              onLongPress: () async {
                final action = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: Text(g.title),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'edit'),
                        child: const Text('Edit'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'delete'),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (action == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoalEditorScreen(goal: g),
                    ),
                  );
                } else if (action == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Удалить цель?'),
                      content: const Text(
                          'Вы уверены, что хотите удалить эту цель?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await goalsEngine.removeGoal(g.id);
                  }
                }
              },
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
