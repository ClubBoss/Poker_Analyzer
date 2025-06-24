import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';

class Achievement {
  final String title;
  final IconData icon;
  final bool completed;

  const Achievement({
    required this.title,
    required this.icon,
    required this.completed,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final StreakService _streakService;

  @override
  void initState() {
    super.initState();
    _streakService = context.read<StreakService>();
    _streakService.addListener(_onStreakChanged);
  }

  void _onStreakChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _streakService.removeListener(_onStreakChanged);
    super.dispose();
  }

  List<Achievement> _buildAchievements() {
    final streak = _streakService.count;
    return [
      const Achievement(
        title: 'Разобрано 5 ошибок',
        icon: Icons.bug_report,
        completed: false,
      ),
      Achievement(
        title: '3 дня подряд',
        icon: Icons.local_fire_department,
        completed: streak >= 3,
      ),
      const Achievement(
        title: 'Цель выполнена',
        icon: Icons.flag,
        completed: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _buildAchievements();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final a = achievements[index];
          final color = a.completed ? Colors.white : Colors.white54;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(a.icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    a.title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: a.completed ? Colors.green : Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
