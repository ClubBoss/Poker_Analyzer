import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/user_goal.dart';

class GoalToastService {
  static const _progressPrefix = 'goal_toast_progress_';
  static const _lastKey = 'goal_toast_last';
  static const _minInterval = Duration(minutes: 5);

  void maybeShowToast(UserGoal goal, double newProgress) {
    unawaited(_maybeShowToast(goal, newProgress));
  }

  Future<void> _maybeShowToast(UserGoal goal, double newProgress) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getDouble('$_progressPrefix${goal.id}') ?? 0.0;
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (newProgress - old < 10) {
      await prefs.setDouble('$_progressPrefix${goal.id}', newProgress);
      return;
    }
    if (last != null && now.difference(last) < _minInterval) {
      await prefs.setDouble('$_progressPrefix${goal.id}', newProgress);
      return;
    }
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      final oldPct = old.toStringAsFixed(0);
      final newPct = newProgress.toStringAsFixed(0);
      final tag = goal.tag ?? goal.title;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('🎯 Прогресс по цели #$tag: $oldPct% → $newPct%'),
        ),
      );
    }
    await prefs.setDouble('$_progressPrefix${goal.id}', newProgress);
    await prefs.setString(_lastKey, now.toIso8601String());
  }
}
