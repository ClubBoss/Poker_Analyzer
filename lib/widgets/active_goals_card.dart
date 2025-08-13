import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/user_goal_engine.dart';
import '../screens/goals_history_screen.dart';

class ActiveGoalsCard extends StatelessWidget {
  const ActiveGoalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<UserGoalEngine>();
    final accent = Theme.of(context).colorScheme.secondary;
    final goals = engine.goals.where((g) => !g.completed).toList();
    if (goals.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Active Goals',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoalsHistoryScreen(),
                    ),
                  );
                },
                child: const Text('History'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < goals.length; i++) ...[
            Text(goals[i].title, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (engine.progress(goals[i]) / goals[i].target)
                    .clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${engine.progress(goals[i])}/${goals[i].target}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            if (i != goals.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
