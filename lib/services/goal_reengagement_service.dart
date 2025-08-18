import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_goal.dart';
import '../models/goal_engagement.dart';
import '../models/goal_progress.dart';
import 'pack_library_loader_service.dart';
import 'goal_engagement_tracker.dart';
import 'session_log_service.dart';
import 'smart_goal_reminder_engine.dart';
import 'smart_goal_tracking_service.dart';
import 'goal_completion_engine.dart';

/// Central service for selecting stale goals and tracking dismiss actions.
class GoalReengagementService {
  final SessionLogService logs;

  GoalReengagementService({required this.logs});

  static const _prefsKey = 'goal_reengagement_dismissed';

  final Map<String, int> _dismissed = {};
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          for (final entry in data.entries) {
            _dismissed[entry.key.toString()] = (entry.value as num).toInt();
          }
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({for (final e in _dismissed.entries) e.key: e.value}),
    );
  }

  /// Picks the highest value training goal for re-engagement or `null` if none.
  Future<TrainingGoal?> pickReengagementGoal() async {
    await _load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final tags = <String>{};
    for (final p in PackLibraryLoaderService.instance.library) {
      tags.addAll(p.tags.map((e) => e.trim().toLowerCase()));
    }
    final tracker = SmartGoalTrackingService(logs: logs);
    final allGoals = <GoalProgress>[];
    for (final t in tags) {
      final gp = await tracker.getGoalProgress(t);
      allGoals.add(gp);
    }
    final log = await GoalEngagementTracker.instance.getAll();
    const engine = SmartGoalReminderEngine();
    final staleTags = await engine.getStaleGoalTags(
      staleDays: 5,
      allGoals: allGoals,
      engagementLog: log,
    );

    TrainingGoal? best;
    double bestScore = double.negativeInfinity;
    for (final tag in staleTags) {
      if ((_dismissed[tag] ?? 0) >= 3) continue;
      final progress = allGoals.firstWhere((g) => g.tag == tag);
      if (GoalCompletionEngine.instance.isGoalCompleted(progress)) continue;
      final score =
          (3 - progress.stagesCompleted).toDouble() +
          (100 - progress.averageAccuracy) / 100;
      if (score > bestScore) {
        bestScore = score;
        best = TrainingGoal('Продолжи цель: $tag', tag: tag);
      }
    }
    return best;
  }

  /// Increments dismissal counter for [tag] and logs the event.
  Future<void> markDismissed(String tag) async {
    final key = tag.trim().toLowerCase();
    await _load();
    _dismissed[key] = (_dismissed[key] ?? 0) + 1;
    await _save();
    await GoalEngagementTracker.instance.log(
      GoalEngagement(tag: key, action: 'dismiss', timestamp: DateTime.now()),
    );
  }
}
