import '../models/learning_goal.dart';
import 'weakness_cluster_engine.dart';

class LearningGoalEngine {
  const LearningGoalEngine();

  List<LearningGoal> generateGoals(List<WeaknessCluster> clusters) {
    if (clusters.isEmpty) return const [];
    final grouped = <String, List<WeaknessCluster>>{};
    for (final c in clusters) {
      final key = _groupKey(c.tag);
      grouped.putIfAbsent(key, () => []).add(c);
    }

    final goals = <LearningGoal>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    var index = 0;
    for (final e in grouped.entries) {
      final list = e.value;
      list.sort((a, b) => b.severity.compareTo(a.severity));
      final best = list.first;
      final id = 'lg_${now}_${index++}';
      final title = _titleFor(best);
      final desc = _descFor(best);
      goals.add(
        LearningGoal(
          id: id,
          title: title,
          description: desc,
          tag: e.key,
          priorityScore: best.severity,
        ),
      );
    }
    goals.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return goals;
  }

  String _groupKey(String tag) {
    final parts = tag.toLowerCase().split(RegExp(r'[\s_/\\-]+'));
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

  String _titleFor(WeaknessCluster c) {
    switch (c.reason) {
      case 'many mistakes':
        return 'Reduce mistakes in ${c.tag}';
      case 'low EV':
        return 'Improve EV in ${c.tag}';
      case 'low mastery':
        return 'Improve mastery for ${c.tag}';
      default:
        return 'Improve ${c.tag}';
    }
  }

  String _descFor(WeaknessCluster c) {
    switch (c.reason) {
      case 'many mistakes':
        return 'Focus on ${c.tag} spots to avoid common mistakes.';
      case 'low EV':
        return 'Work on ${c.tag} hands to increase expected value.';
      case 'low mastery':
        return 'Study ${c.tag} hands to raise mastery level.';
      default:
        return 'Practice ${c.tag} hands to improve.';
    }
  }
}
