import '../models/goal_progress.dart';
import '../services/goal_completion_engine.dart';

/// Returns a human readable status string for a goal.
String getGoalStatus(GoalProgress progress) {
  if (GoalCompletionEngine.instance.isGoalCompleted(progress)) {
    return '✔ Завершено';
  }
  final accuracy = progress.averageAccuracy.toStringAsFixed(0);
  return 'Пройдено: ${progress.stagesCompleted}/${progress.totalStages} · Точность: $accuracy%';
}
