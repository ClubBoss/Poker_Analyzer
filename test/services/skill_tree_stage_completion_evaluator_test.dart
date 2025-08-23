import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/skill_tree_stage_completion_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreeBuilderService();
  const evaluator = SkillTreeStageCompletionEvaluator();

  SkillTreeNodeModel node(String id, int level) =>
      SkillTreeNodeModel(id: id, title: id, category: 'Push/Fold', level: level);

  class OptionalNode extends SkillTreeNodeModel {
    final bool isOptional;
  const OptionalNode({required String id, required int level})
        : isOptional = true,
          super(id: id, title: id, category: 'Push/Fold', level: level);
  }

  test('detects completed stages', () {
    final tree = builder.build([
      node('n1', 0),
      node('n2', 0),
      node('n3', 1),
      node('n4', 1),
    ]).tree;
    final completed = {'n1', 'n2', 'n3'};
    expect(evaluator.isStageCompleted(tree, 0, completed), isTrue);
    expect(evaluator.isStageCompleted(tree, 1, completed), isFalse);
    final stages = evaluator.getCompletedStages(tree, completed);
    expect(stages, [0]);
  });

  test('optional nodes do not block completion', () {
    const optNode = OptionalNode(id: 'opt', level: 1);
    final tree = builder.build([
      node('n1', 0),
      optNode,
    ]).tree;
    final completed = {'n1'};
    expect(evaluator.isStageCompleted(tree, 1, completed), isTrue);
  });
}
