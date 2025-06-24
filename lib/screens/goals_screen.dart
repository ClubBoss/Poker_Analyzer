import 'package:flutter/material.dart';

class Goal {
  final String title;
  final int progress;
  final int target;
  final IconData? icon;

  const Goal({
    required this.title,
    required this.progress,
    required this.target,
    this.icon,
  });
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  static const List<Goal> _goals = [
    Goal(
      title: 'Разобрать 5 ошибок',
      progress: 2,
      target: 5,
      icon: Icons.bug_report,
    ),
    Goal(
      title: 'Пройти 3 раздачи без ошибок подряд',
      progress: 1,
      target: 3,
      icon: Icons.play_circle_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои цели'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _goals.length,
        itemBuilder: (context, index) {
          final goal = _goals[index];
          final progress = (goal.progress / goal.target).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                    if (goal.icon != null) ...[
                      Icon(goal.icon, color: accent),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('${goal.progress}/${goal.target}'),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
