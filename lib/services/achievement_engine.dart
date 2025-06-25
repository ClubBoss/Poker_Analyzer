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
  final Map<String, bool> _shown = {};

  List<Achievement> get achievements => List.unmodifiable(_achievements);

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
      _shown[k] = prefs.getBool('ach_shown_$k') ?? false;
    }
  }

  Future<void> _save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ach_shown_$key', true);
  }

  void _sync() {
    _achievements
      ..clear()
      ..addAll([
        Achievement(
          title: '10 тренировок',
          icon: Icons.play_circle_fill,
          progress: stats.sessionsCompleted,
          target: 10,
        ),
        Achievement(
          title: '50 раздач разобрано',
          icon: Icons.menu_book,
          progress: stats.handsReviewed,
          target: 50,
        ),
        Achievement(
          title: '10 ошибок исправлено',
          icon: Icons.build,
          progress: stats.mistakesFixed,
          target: 10,
        ),
      ]);
    notifyListeners();
  }

  void _onUpdate(String key) {
    _sync();
    final index = {'s': 0, 'h': 1, 'm': 2}[key]!;
    final ach = _achievements[index];
    if (!_shown[key]! && ach.completed) {
      _shown[key] = true;
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
}
