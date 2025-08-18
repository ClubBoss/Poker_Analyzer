import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/services/skill_tree_track_summary_builder.dart';
import 'package:poker_analyzer/services/training_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  final tracker = SkillTreeNodeProgressTracker.instance;

  SkillTreeNodeModel node(String id, {List<String>? prereqs}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: 'Push/Fold',
        prerequisites: prereqs,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await tracker.resetForTest();
  });

  test('builds summary with ev loss stats', () async {
    final tree = builder.build([node('a'), node('b')]).tree;
    await tracker.markCompleted('a');
    final stats = TrainingStatsService();
    await stats.updateSkill('Push/Fold', -0.5, true);
    final summary = await SkillTreeTrackSummaryBuilder(
      progress: tracker,
      stats: stats,
    ).build(tree);
    expect(summary.title, 'Push/Fold');
    expect(summary.completedCount, 1);
    expect(summary.avgEvLoss, closeTo(-0.5, 0.0001));
    expect(summary.motivationalLine.isNotEmpty, isTrue);
  });

  test('generates completion message when all done', () async {
    final tree = builder.build([node('c')]).tree;
    await tracker.markCompleted('c');
    final summary = await SkillTreeTrackSummaryBuilder(
      progress: tracker,
    ).build(tree);
    expect(summary.completedCount, 1);
    expect(summary.motivationalLine.toLowerCase(), contains('crushed'));
  });
}
