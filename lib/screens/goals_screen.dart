import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../services/streak_service.dart';

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
    final bonus = context.watch<StreakService>().hasBonus;
    final multiplier = bonus ? StreakService.bonusMultiplier : 1.0;

    List<Widget> children = [];
    if (bonus) {
      children.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔥 Бонус за серию — ускоренный прогресс целей!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (final goal in _goals) {
      final adjusted = math.min((goal.progress * multiplier).round(), goal.target);
      final progress = (adjusted / goal.target).clamp(0.0, 1.0);
      children.add(
        Container(
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
                  Text('$adjusted/${goal.target}'),
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои цели'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      ),
    );
  }
}
