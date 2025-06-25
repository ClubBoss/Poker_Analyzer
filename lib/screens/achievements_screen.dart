import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/app_colors.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _weekly = false;
  int _correct = 0;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = context.read<GoalsService>();
    final manager = context.read<SavedHandManagerService>();
    final summary = EvaluationExecutorService().summarizeHands(manager.hands);
    final weekly = await goals.hasWeeklyStreak();
    final history = await goals.getDailySpotHistory();
    if (!mounted) return;
    setState(() {
      _correct = summary.correct;
      _weekly = weekly;
      _active = history.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '🎯',
        '100 правильных решений',
        'Вы сыграли 100 раздач без ошибки',
        _correct >= 100
      ),
      (
        '🔥',
        'Серия 7 дней',
        'Выполняйте Спот дня семь дней подряд',
        _weekly
      ),
      (
        '📅',
        '30 дней активности',
        'Завершите Спот дня 30 раз',
        _active >= 30
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final i = items[index];
          final unlocked = i.$4;
          final color = unlocked ? Colors.white : Colors.white54;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Text(i.$1, style: const TextStyle(fontSize: 28)),
              title: Text(i.$2,
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.bold)),
              subtitle:
                  Text(i.$3, style: const TextStyle(color: Colors.white70)),
              trailing: Icon(
                unlocked ? Icons.check_circle : Icons.lock,
                color: unlocked ? Colors.green : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}
