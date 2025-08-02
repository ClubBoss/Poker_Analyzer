import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_node_completion_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = SkillTreeNodeCompletionStateService();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'cat');

  class OptionalNode extends SkillTreeNodeModel {
    final bool isOptional;
    const OptionalNode(String id)
        : isOptional = true,
          super(id: id, title: id, category: 'cat');
  }

  test('detects locked and unlocked nodes', () {
    const u = {'n1'};
    const c = <String>{};
    expect(
      service.getNodeState(node: node('n0'), unlocked: u, completed: c),
      SkillTreeNodeState.locked,
    );
    expect(
      service.getNodeState(node: node('n1'), unlocked: u, completed: c),
      SkillTreeNodeState.unlocked,
    );
  });

  test('detects completed nodes', () {
    const u = {'n1'};
    const c = {'n1'};
    expect(
      service.getNodeState(node: node('n1'), unlocked: u, completed: c),
      SkillTreeNodeState.completed,
    );
  });

  test('treats optional nodes as optional and completed', () {
    const u = <String>{};
    const c = <String>{};
    final n = OptionalNode('opt');
    expect(
      service.getNodeState(node: n, unlocked: u, completed: c),
      SkillTreeNodeState.optional,
    );
    // Optional nodes are also considered completed for progress.
    expect(
      service.getNodeState(node: n, unlocked: u, completed: {'opt'}),
      SkillTreeNodeState.optional,
    );
  });
}

