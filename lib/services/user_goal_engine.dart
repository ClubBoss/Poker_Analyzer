import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'preferences_service.dart';
import '../models/user_goal.dart';
import '../widgets/confetti_overlay.dart';
import '../main.dart';
import 'training_stats_service.dart';
import 'xp_tracker_service.dart';
import 'goal_analytics_service.dart';
import 'goal_sync_service.dart';

class UserGoalEngine extends ChangeNotifier {
  static const _prefsKey = 'user_goals';
  final TrainingStatsService stats;
  final GoalSyncService? sync;

  UserGoalEngine({required this.stats, this.sync}) {
    _init();
  }

  final List<UserGoal> _goals = [];

  List<UserGoal> get goals => List.unmodifiable(_goals);

  Future<void> _init() async {
    await _load();
    if (sync != null && sync!.uid != null) {
      try {
        final remote = await sync!.download();
        _merge(remote);
      } catch (_) {}
    }
    _update();
    stats.sessionsStream.listen((_) => _update());
    stats.handsStream.listen((_) => _update());
    stats.mistakesStream.listen((_) => _update());
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      _goals
        ..clear()
        ..addAll(UserGoal.decode(raw));
    }
  }

  Future<void> _save() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, UserGoal.encode(_goals));
    unawaited(sync?.upload(_goals));
  }

  void _merge(List<UserGoal> remote) {
    bool changed = false;
    for (final r in remote) {
      final index = _goals.indexWhere((g) => g.id == r.id);
      if (index == -1) {
        _goals.add(r);
        changed = true;
      } else {
        final local = _goals[index];
        final localAt = local.completedAt ?? local.createdAt;
        final remoteAt = r.completedAt ?? r.createdAt;
        if (remoteAt.isAfter(localAt)) {
          _goals[index] = r;
          changed = true;
        }
      }
    }
    if (changed) unawaited(_save());
  }

  int _statValue(String type) {
    switch (type) {
      case 'sessions':
        return stats.sessionsCompleted;
      case 'hands':
        return stats.handsReviewed;
      default:
        return stats.mistakesFixed;
    }
  }

  int progress(UserGoal g) => _statValue(g.type) - g.base;

  void _completeGoal(UserGoal g) {
    unawaited(_save());
    unawaited(GoalAnalyticsService.instance.logGoalCompleted(g));
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showConfettiOverlay(ctx);
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text('Goal completed: ${g.title}')));
      unawaited(
        ctx.read<XPTrackerService>().add(
              xp: XPTrackerService.achievementXp,
              source: 'goal',
            ),
      );
    }
  }

  void _update() {
    final sessions = stats.sessionsCompleted;
    final hands = stats.handsReviewed;
    final mistakes = stats.mistakesFixed;
    for (var i = 0; i < _goals.length; i++) {
      final g = _goals[i];
      if (g.completed) continue;
      final current = switch (g.type) {
        'sessions' => sessions,
        'hands' => hands,
        _ => mistakes,
      };
      if (current - g.base >= g.target) {
        _goals[i] = g.copyWith(completedAt: DateTime.now());
        _completeGoal(_goals[i]);
      }
    }
    notifyListeners();
  }

  Future<void> addGoal(UserGoal g) async {
    _goals.add(g);
    unawaited(GoalAnalyticsService.instance.logGoalCreated(g));
    await _save();
    notifyListeners();
  }

  Future<void> removeGoal(String id) async {
    _goals.removeWhere((g) => g.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> updateGoal(UserGoal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) return;
    _goals[index] = goal;
    await _save();
    _update();
  }
}
