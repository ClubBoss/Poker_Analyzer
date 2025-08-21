import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/services/skill_tree_node_detail_unlock_hint_service.dart';

void main() {
  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(
    String id, {
    List<String>? prerequisites,
    List<String>? unlocks,
    int level = 0,
  }) => SkillTreeNodeModel(
    id: id,
    title: id,
    category: 'cat',
    prerequisites: prerequisites,
    unlockedNodeIds: unlocks,
    level: level,
  );

  SkillTree buildTree(List<SkillTreeNodeModel> nodes) =>
      builder.build(nodes).tree;

  test('returns null for unlocked node', () {
    final n1 = node('n1', unlocks: ['n2']);
    final n2 = node('n2', prerequisites: ['n1']);
    final tree = buildTree([n1, n2]);
    final svc = const SkillTreeNodeDetailUnlockHintService();
    final hint = svc.getUnlockHint(
      node: n2,
      unlocked: {'n2'},
      completed: {'n1'},
      track: tree,
    );
    expect(hint, isNull);
  });

  test('reports missing prerequisite', () {
    final n1 = node('n1', unlocks: ['n2']);
    final n2 = node('n2', prerequisites: ['n1']);
    final tree = buildTree([n1, n2]);
    final svc = const SkillTreeNodeDetailUnlockHintService();
    final hint = svc.getUnlockHint(
      node: n2,
      unlocked: {},
      completed: {},
      track: tree,
    );
    expect(hint, 'Complete n1 to unlock this node');
  });

  test('reports locked stage', () {
    final n1 = node('n1', unlocks: ['n2'], level: 0);
    final n2 = node('n2', unlocks: ['n3'], level: 1);
    final n3 = node('n3', prerequisites: ['n2'], level: 2);
    final tree = buildTree([n1, n2, n3]);
    final svc = const SkillTreeNodeDetailUnlockHintService();
    final hint = svc.getUnlockHint(
      node: n3,
      unlocked: {},
      completed: {'n1'},
      track: tree,
    );
    expect(hint, 'Complete n2 to unlock this node');
  });
}
