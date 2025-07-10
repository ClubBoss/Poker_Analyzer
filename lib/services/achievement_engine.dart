import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../widgets/confetti_overlay.dart';
import 'training_stats_service.dart';
import '../main.dart';
import 'user_action_logger.dart';

class AchievementEngine extends ChangeNotifier {
  static AchievementEngine? _instance;
  static AchievementEngine get instance => _instance!;

  final TrainingStatsService stats;

  AchievementEngine({required this.stats}) {
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
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in ['s', 'h', 'm']) {
      _shown[k] = prefs.getInt('ach_level_$k') ?? 0;
    }
    _unseen = prefs.getInt('ach_unseen') ?? 0;
  }

  Future<void> _save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ach_level_$key', _shown[key]!);
    await prefs.setInt('ach_unseen', _unseen);
  }

  Future<void> _saveUnseen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ach_unseen', _unseen);
  }

  void _sync() {
    const sessionThresholds = [10, 25, 50, 100, 200];
    const handThresholds = [50, 200, 500, 1000, 2000];
    const mistakeThresholds = [10, 25, 50, 100, 200];
    _achievements
      ..clear()
      ..addAll([
        Achievement(
          title: 'Тренировки',
          description: 'Завершайте тренировочные сессии',
          icon: Icons.play_circle_fill,
          progress: stats.sessionsCompleted,
          thresholds: sessionThresholds,
        ),
        Achievement(
          title: 'Разборы раздач',
          description: 'Разбирайте сыгранные руки',
          icon: Icons.menu_book,
          progress: stats.handsReviewed,
          thresholds: handThresholds,
        ),
        Achievement(
          title: 'Исправленные ошибки',
          description: 'Устраняйте найденные ошибки',
          icon: Icons.build,
          progress: stats.mistakesFixed,
          thresholds: mistakeThresholds,
        ),
      ]);
    notifyListeners();
  }

  void _onUpdate(String key) {
    _sync();
    final index = {'s': 0, 'h': 1, 'm': 2}[key]!;
    final ach = _achievements[index];
    final prev = _shown[key] ?? 0;
    if (ach.level > prev) {
      _shown[key] = ach.level;
      _unseen += 1;
      _save(key);
      UserActionLogger.instance.log('unlocked_achievement:${ach.title}');
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        showConfettiOverlay(ctx);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Achievement unlocked: ${ach.title}')),
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
