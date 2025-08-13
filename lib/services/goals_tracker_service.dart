import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import 'reward_service.dart';
import 'training_stats_service.dart';

class GoalsTrackerService extends ChangeNotifier {
  final RewardService rewards;
  final TrainingStatsService stats;
  GoalsTrackerService({required this.rewards, required this.stats}) {
    _init();
  }

  final Map<String, List<Goal>> _all = {
    'daily': [
      Goal(
          id: 'd1',
          title: 'Play 10 hands',
          type: 'daily',
          target: 10,
          reward: 5),
      Goal(
          id: 'd2',
          title: 'Play 20 hands',
          type: 'daily',
          target: 20,
          reward: 10),
    ],
    'weekly': [
      Goal(
          id: 'w1',
          title: 'Finish 3 packs',
          type: 'weekly',
          target: 3,
          reward: 20),
      Goal(
          id: 'w2',
          title: 'Finish 5 packs',
          type: 'weekly',
          target: 5,
          reward: 40),
    ],
    'progressive': [
      Goal(
          id: 'p1',
          title: 'Play 1000 hands',
          type: 'progressive',
          target: 1000,
          reward: 50),
      Goal(
          id: 'p2',
          title: 'Play 5000 hands',
          type: 'progressive',
          target: 5000,
          reward: 200),
    ],
  };

  final Map<String, int> _index = {'daily': 0, 'weekly': 0, 'progressive': 0};

  List<Goal> get activeGoals => [for (final t in _all.keys) _current(t)];

  Future<void> _init() async {
    await _load();
    stats.handsStream.listen((_) => _onHand());
    stats.sessionsStream.listen((_) => _onSession());
  }

  Goal _current(String type) => _all[type]![_index[type]!];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in _all.keys) {
      _index[t] = prefs.getInt('goal_${t}_index') ?? 0;
      final g = _current(t);
      g.progress = prefs.getInt('goal_${t}_progress') ?? 0;
      g.completed = prefs.getBool('goal_${t}_completed') ?? false;
    }
  }

  Future<void> _save(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final g = _current(type);
    await prefs.setInt('goal_${type}_index', _index[type]!);
    await prefs.setInt('goal_${type}_progress', g.progress);
    await prefs.setBool('goal_${type}_completed', g.completed);
  }

  void _onHand() {
    _inc('daily');
    _inc('progressive');
  }

  void _onSession() {
    _inc('weekly');
  }

  Future<void> claim(String type) async {
    final g = _current(type);
    if (g.progress < g.target || g.completed) return;
    await rewards.add(g.reward);
    g.completed = true;
    await _save(type);
    if (_index[type]! < _all[type]!.length - 1) {
      _index[type] = _index[type]! + 1;
      await _save(type);
    }
    notifyListeners();
  }

  void _inc(String type) {
    final g = _current(type);
    if (g.completed) return;
    g.progress += 1;
    _check(type);
  }

  void _check(String type) {
    final g = _current(type);
    if (g.progress >= g.target) {
      // wait for claim
    }
    _save(type);
    notifyListeners();
  }
}
