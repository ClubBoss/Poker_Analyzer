import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'preferences_service.dart';
import '../models/goal.dart';
import '../utils/singleton_mixin.dart';

class GoalEngine extends ChangeNotifier with SingletonMixin<GoalEngine> {
  GoalEngine._() {
    _init();
  }

  static GoalEngine get instance =>
      SingletonMixin.instance<GoalEngine>(() => GoalEngine._());

  static const _prefsKey = 'xp_goals';
  final List<Goal> _goals = [];
  List<Goal> get goals => List.unmodifiable(_goals);

  Future<void> _init() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as List;
        _goals.addAll(data.map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {
        _goals.addAll(_defaultGoals());
      }
    } else {
      _goals.addAll(_defaultGoals());
    }
    notifyListeners();
  }

  List<Goal> _defaultGoals() {
    final now = DateTime.now();
    return [
      Goal(
        id: 'daily',
        title: 'Earn 200 XP today',
        type: GoalType.daily,
        targetXP: 200,
        currentXP: 0,
        deadline: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
      ),
      Goal(
        id: 'weekly',
        title: 'Reach level 10 this week',
        type: GoalType.weekly,
        targetXP: 1000,
        currentXP: 0,
        deadline: DateTime(now.year, now.month, now.day).add(Duration(days: 8 - now.weekday)),
      ),
      Goal(
        id: 'progress',
        title: 'Earn 10K XP all-time',
        type: GoalType.progressive,
        targetXP: 10000,
        currentXP: 0,
        deadline: DateTime.now().add(const Duration(days: 3650)),
      ),
    ];
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, jsonEncode([for (final g in _goals) g.toJson()]));
  }

  Future<void> updateXP(int xpDelta) async {
    for (final g in _goals) {
      if (g.completed) continue;
      if (g.deadline.isBefore(DateTime.now())) continue;
      g.currentXP += xpDelta;
    }
    await checkCompletions();
  }

  Future<void> checkCompletions() async {
    bool changed = false;
    for (final g in _goals) {
      if (!g.completed && g.currentXP >= g.targetXP && g.deadline.isAfter(DateTime.now())) {
        g.completed = true;
        changed = true;
      }
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }
}
