import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_stage_badge_evaluator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = SkillTreeStageBadgeEvaluatorService();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'cat', level: 1);

  class OptionalNode extends SkillTreeNodeModel {
    final bool isOptional;
    const OptionalNode(String id)
        : isOptional = true,
          super(id: id, title: id, category: 'cat', level: 1);
  }

  test('returns locked badge when stage locked', () {
    final nodes = [node('a')];
    expect(
      service.getBadge(nodes: nodes, unlocked: {}, completed: {}),
      'locked',
    );
  });

  test('returns in_progress when stage unlocked but not completed', () {
    final nodes = [node('a')];
    expect(
      service.getBadge(nodes: nodes, unlocked: {'a'}, completed: {}),
      'in_progress',
    );
  });

  test('returns perfect when all nodes completed', () {
    final nodes = [node('a'), node('b')];
    expect(
      service.getBadge(
        nodes: nodes,
        unlocked: {'a', 'b'},
        completed: {'a', 'b'},
      ),
      'perfect',
    );
  });

  test('not perfect when optional nodes remain', () {
    final nodes = [node('a'), OptionalNode('b')];
    expect(
      service.getBadge(
        nodes: nodes,
        unlocked: {'a'},
        completed: {'a'},
      ),
      'in_progress',
    );
  });
}
