import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../widgets/confetti_overlay.dart';
import 'training_stats_service.dart';
import 'goals_service.dart';
import 'reward_system_service.dart';
import '../models/achievement_progress.dart';
import '../main.dart';
import 'user_action_logger.dart';

class AchievementEngine extends ChangeNotifier {
  static AchievementEngine? _instance;
  static AchievementEngine get instance => _instance!;

  final TrainingStatsService stats;
  final GoalsService goals;

  AchievementEngine({required this.stats, required this.goals}) {
    _instance = this;
    _init();
  }

  final List<Achievement> _achievements = [];
  final Map<String, int> _shown = {};
  int _unseen = 0;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  int get unseenCount => _unseen;

  Future<void> _init() async {
    await _load();
    _sync();
    stats.sessionsStream.listen((_) => _onUpdate('s'));
    stats.handsStream.listen((_) => _onUpdate('h'));
    stats.mistakesStream.listen((_) => _onUpdate('m'));
    goals.addListener(() => _onUpdate('w'));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in ['s', 'h', 'm', 'w']) {
      _shown[k] = prefs.getInt('ach_level_$k') ?? 0;
    }
    _unseen = prefs.getInt('ach_unseen') ?? 0;
  }

  Future<void> _save(String key, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ach_level_$key', level);
    await prefs.setInt('ach_unseen', _unseen);
  }

  Future<void> _saveUnseen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ach_unseen', _unseen);
  }

  void _sync() {
    _achievements
      ..clear()
      ..addAll([
        Achievement(
          title: 'Тренировки',
          description: 'Завершайте тренировочные сессии',
          icon: Icons.play_circle_fill,
          progress: stats.sessionsCompleted,
          thresholds: const [10, 30, 60, 100, 150],
        ),
        Achievement(
          title: 'Разбор раздач',
          description: 'Разбирайте сыгранные раздачи',
          icon: Icons.menu_book,
          progress: stats.handsReviewed,
          thresholds: const [50, 150, 300, 600, 1000],
        ),
        Achievement(
          title: 'Исправление ошибок',
          description: 'Исправляйте найденные ошибки',
          icon: Icons.build,
          progress: stats.mistakesFixed,
          thresholds: const [10, 25, 50, 100, 200],
        ),
        Achievement(
          title: 'Точность недели',
          description: 'Достигайте точности за неделю',
          icon: Icons.show_chart,
          progress: goals.weeklyAccuracyProgress().round(),
          thresholds: [goals.weeklyAccuracyTarget.round()],
        ),
      ]);
    notifyListeners();
  }

  void _onUpdate(String key) {
    _sync();
    final index = {'s': 0, 'h': 1, 'm': 2, 'w': 3}[key]!;
    final ach = _achievements[index];
    final level = ach.levelIndex;
    if ((_shown[key] ?? 0) < level) {
      _shown[key] = level;
      _unseen += 1;
      _save(key, level);
      UserActionLogger.instance.log('unlocked_achievement:${ach.title}_$level');
      RewardSystemService.instance.applyAchievementReward(
        AchievementProgress(level),
      );
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        showConfettiOverlay(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Achievement level up: ${ach.title}')),
        );
      }
    }
  }

  Future<void> markSeen() async {
    if (_unseen == 0) return;
    _unseen = 0;
    await _saveUnseen();
    notifyListeners();
  }
}
