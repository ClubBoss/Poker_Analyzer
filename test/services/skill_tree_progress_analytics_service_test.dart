import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_progress_analytics_service.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  final analytics = SkillTreeProgressAnalyticsService();

  SkillTreeNodeModel node(String id, {List<String>? prereqs, int level = 0}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: 'Push/Fold',
        prerequisites: prereqs,
        level: level,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reports completion stats by level', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final tree = builder.build([
      node('n1', level: 0),
      node('n2', prereqs: ['n1'], level: 0),
      node('n3', prereqs: ['n2'], level: 1),
    ]).tree;

    await tracker.markCompleted('n1');
    await tracker.markCompleted('n2');

    final stats = await analytics.getStats(tree);

    expect(stats.totalNodes, 3);
    expect(stats.completedNodes, 2);
    expect(stats.completionRate, closeTo(2 / 3, 1e-6));
    expect(stats.completionRateByLevel[0], closeTo(1.0, 1e-6));
    expect(stats.completionRateByLevel[1], closeTo(0.0, 1e-6));
  });
}
