import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_tree_stage_gate_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  const evaluator = SkillTreeStageGateEvaluator();

  SkillTreeNodeModel node(String id, int level) => SkillTreeNodeModel(
      id: id, title: id, category: 'Push/Fold', level: level);

  test('stage 0 always unlocked', () {
    final tree = builder.build([node('n1', 0)]).tree;
    expect(evaluator.isStageUnlocked(tree, 0, {}), isTrue);
  });

  test('requires prior stages to be completed', () {
    final tree = builder.build([
      node('n1', 0),
      node('n2', 1),
      node('n3', 2),
    ]).tree;
    final completed = {'n1'};
    expect(evaluator.isStageUnlocked(tree, 1, completed), isTrue);
    expect(evaluator.isStageUnlocked(tree, 2, completed), isFalse);
    final stages = evaluator.getUnlockedStages(tree, completed);
    expect(stages, [0, 1]);
  });

  test('later stages unlock when all previous are completed', () {
    final tree = builder.build([
      node('n1', 0),
      node('n2', 1),
      node('n3', 2),
    ]).tree;
    final completed = {'n1', 'n2', 'n3'};
    expect(evaluator.isStageUnlocked(tree, 2, completed), isTrue);
  });

  test('getBlockingNodes returns incomplete prior stage nodes', () {
    final tree = builder.build([
      node('n1', 0),
      node('n2', 1),
      node('n3', 2),
    ]).tree;
    final completed = {'n1'};
    final blocking = evaluator.getBlockingNodes(tree, 2, completed);
    expect(blocking.map((n) => n.id), ['n2']);
  });
}
