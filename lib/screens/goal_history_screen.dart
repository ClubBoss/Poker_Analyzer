import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';

class GoalHistoryScreen extends StatelessWidget {
  const GoalHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GoalsService>();
    final accent = Theme.of(context).colorScheme.secondary;
    final goals = service.goals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История целей'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final g = goals[index];
          final completed = g.progress >= g.target;
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
                if (g.icon != null) ...[
                  Icon(g.icon, color: accent),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (completed && g.completedAt != null)
                        Text('Завершено: ${_formatDate(g.completedAt!)}')
                      else
                        Text('${g.progress}/${g.target}')
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  completed ? Icons.check_circle : Icons.timelapse,
                  color: completed ? Colors.green : Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
