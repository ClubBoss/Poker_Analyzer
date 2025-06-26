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
      _shown[k] = prefs.getBool('ach_shown_$k') ?? false;
    }
    _unseen = prefs.getInt('ach_unseen') ?? 0;
  }

  Future<void> _save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ach_shown_$key', true);
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
          title: '10 тренировок',
          description: 'Завершите 10 тренировочных сессий',
          icon: Icons.play_circle_fill,
          progress: stats.sessionsCompleted,
          target: 10,
        ),
        Achievement(
          title: '50 раздач разобрано',
          description: 'Разберите 50 раздач',
          icon: Icons.menu_book,
          progress: stats.handsReviewed,
          target: 50,
        ),
        Achievement(
          title: '10 ошибок исправлено',
          description: 'Исправьте 10 ошибок',
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
