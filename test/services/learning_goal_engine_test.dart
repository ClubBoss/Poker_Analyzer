import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_goal_engine.dart';
import 'package:poker_analyzer/services/weakness_cluster_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates goals sorted by severity', () {
    const engine = LearningGoalEngine();
    final clusters = [
      const WeaknessCluster(tag: 'btn push', reason: 'low EV', severity: 0.3),
      const WeaknessCluster(
        tag: 'sb vs bb',
        reason: 'many mistakes',
        severity: 0.7,
      ),
    ];

    final goals = engine.generateGoals(clusters);

    expect(goals.length, 2);
    expect(goals.first.priorityScore, greaterThan(goals.last.priorityScore));
    expect(goals.first.title.isNotEmpty, true);
    expect(goals.first.description.isNotEmpty, true);
  });

  test('groups similar tags', () {
    const engine = LearningGoalEngine();
    final clusters = [
      const WeaknessCluster(
        tag: 'btn push 10bb',
        reason: 'low EV',
        severity: 0.4,
      ),
      const WeaknessCluster(
        tag: 'btn push 12bb',
        reason: 'many mistakes',
        severity: 0.5,
      ),
    ];

    final goals = engine.generateGoals(clusters);

    expect(goals.length, 1);
    expect(goals.first.tag, 'btn push');
  });
}
