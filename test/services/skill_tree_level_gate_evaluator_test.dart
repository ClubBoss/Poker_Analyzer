import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/skill_tree_level_gate_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();

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

  test('levels unlock only after completing previous levels', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();
    final tree = builder.build([
      node('n1', level: 0),
      node('n2', level: 0),
      node('n3', prereqs: ['n1'], level: 1),
      node('n4', prereqs: ['n2', 'n3'], level: 2),
    ]).tree;

    final gate = SkillTreeLevelGateEvaluator(tree: tree, progress: tracker);

    expect(await gate.isLevelUnlocked(0), isTrue);
    expect(await gate.isLevelUnlocked(1), isFalse);
    expect(await gate.getLockedNodeIds(1).then((v) => v.toSet()), {'n1', 'n2'});

    await tracker.markCompleted('n1');
    await tracker.markCompleted('n2');

    expect(await gate.isLevelUnlocked(1), isTrue);
    expect(await gate.getLockedNodeIds(1), isEmpty);

    await tracker.markCompleted('n3');
    expect(await gate.isLevelUnlocked(2), isFalse);
    expect(await gate.getLockedNodeIds(2), ['n4']);

    await tracker.markCompleted('n4');
    expect(await gate.isLevelUnlocked(2), isTrue);
    expect(await gate.getLockedNodeIds(2), isEmpty);
  });
}
