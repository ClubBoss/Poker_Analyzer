import '../models/goal_progress.dart';

class GoalCompletionEngine {
  GoalCompletionEngine._();
  static final instance = GoalCompletionEngine._();

  bool showCompletedGoals = false;
  final Map<String, bool> _cache = {};

  bool isGoalCompleted(GoalProgress progress) {
    final key = progress.tag.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;
    final completed =
        progress.stagesCompleted >= progress.totalStages &&
        progress.averageAccuracy >= 80;
    _cache[key] = completed;
    return completed;
  }
}
