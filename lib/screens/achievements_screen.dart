import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../services/goals_service.dart';

class Achievement {
  final String title;
  final String progressText;
  final IconData icon;
  final bool completed;

  const Achievement({
    required this.title,
    required this.progressText,
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
  late final SavedHandManagerService _handManager;
  late final EvaluationExecutorService _evalService;
  late final GoalsService _goalsService;
  bool _goalCompleted = false;
  int _mistakeCount = 0;

  @override
  void initState() {
    super.initState();
    _streakService = context.read<StreakService>();
    _handManager = context.read<SavedHandManagerService>();
    _evalService = context.read<EvaluationExecutorService>();
    _goalsService = context.read<GoalsService>();
    _goalCompleted = _goalsService.anyCompleted;
    _streakService.addListener(_onStreakChanged);
    _goalsService.addListener(_onGoalsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMistakes());
  }

  void _onStreakChanged() {
    if (mounted) setState(() {});
  }

  void _onGoalsChanged() {
    final done = _goalsService.anyCompleted;
    if (mounted) {
      setState(() => _goalCompleted = done);
    } else {
      _goalCompleted = done;
    }
  }

  void _refreshMistakes() {
    final summary = _evalService.summarizeHands(_handManager.hands);
    if (mounted) {
      setState(() => _mistakeCount = summary.incorrect);
    } else {
      _mistakeCount = summary.incorrect;
    }
  }

  @override
  void dispose() {
    _streakService.removeListener(_onStreakChanged);
    _goalsService.removeListener(_onGoalsChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshMistakes();
    _onGoalsChanged();
  }

  List<Achievement> _buildAchievements() {
    final streak = _streakService.count;
    return [
      Achievement(
        title: 'Разобрано 5 ошибок',
        progressText: '${_mistakeCount.clamp(0, 5)}/5 ошибок',
        icon: Icons.bug_report,
        completed: _mistakeCount >= 5,
      ),
      Achievement(
        title: '3 дня подряд',
        progressText: '${streak.clamp(0, 3)}/3 дня',
        icon: Icons.local_fire_department,
        completed: streak >= 3,
      ),
      Achievement(
        title: 'Цель выполнена',
        progressText: '${_goalCompleted ? 1 : 0}/1 целей',
        icon: Icons.flag,
        completed: _goalCompleted,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.progressText,
                        style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
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
