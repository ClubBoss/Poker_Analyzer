import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/skill_tree_unlock_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  const evaluator = SkillTreeUnlockEvaluator();

  SkillTreeNodeModel node(String id, {List<String>? prereqs}) =>
      SkillTreeNodeModel(
          id: id, title: id, category: 'Push/Fold', prerequisites: prereqs);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns root nodes when no progress', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    final tree = builder.build([
      node('n1'),
      node('n2', prereqs: ['n1']),
    ]).tree;

    final unlocked = evaluator.getUnlockedNodes(tree);
    expect(unlocked.map((n) => n.id), ['n1']);
  });

  test('returns next nodes after completing prerequisites', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    final tree = builder.build([
      node('n1'),
      node('n2', prereqs: ['n1']),
      node('n3', prereqs: ['n1']),
      node('n4', prereqs: ['n2', 'n3']),
    ]).tree;

    var unlocked = evaluator.getUnlockedNodes(tree);
    expect(unlocked.map((n) => n.id).toSet(), {'n1'});

    await tracker.markCompleted('n1');
    unlocked = evaluator.getUnlockedNodes(tree);
    expect(unlocked.map((n) => n.id).toSet(), {'n2', 'n3'});

    await tracker.markCompleted('n2');
    await tracker.markCompleted('n3');
    unlocked = evaluator.getUnlockedNodes(tree);
    expect(unlocked.map((n) => n.id), ['n4']);
  });
}
