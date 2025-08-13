import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_builder_service.dart';
import 'package:poker_analyzer/widgets/skill_tree_node_detail_hint_widget.dart';

void main() {
  const builder = SkillTreeBuilderService();

  SkillTreeNodeModel node(String id,
          {List<String>? prerequisites,
          List<String>? unlocks,
          int level = 0}) =>
      SkillTreeNodeModel(
        id: id,
        title: id,
        category: 'cat',
        prerequisites: prerequisites,
        unlockedNodeIds: unlocks,
        level: level,
      );

  SkillTree buildTree(List<SkillTreeNodeModel> nodes) =>
      builder.build(nodes).tree;

  testWidgets('renders nothing when no hint', (tester) async {
    final n1 = node('n1', unlocks: ['n2']);
    final n2 = node('n2', prerequisites: ['n1']);
    final tree = buildTree([n1, n2]);
    await tester.pumpWidget(MaterialApp(
      home: SkillTreeNodeDetailHintWidget(
        node: n2,
        track: tree,
        unlocked: {'n2'},
        completed: {'n1'},
      ),
    ));
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('shows hint when locked', (tester) async {
    final n1 = node('n1', unlocks: ['n2']);
    final n2 = node('n2', prerequisites: ['n1']);
    final tree = buildTree([n1, n2]);
    await tester.pumpWidget(MaterialApp(
      home: SkillTreeNodeDetailHintWidget(
        node: n2,
        track: tree,
        unlocked: const <String>{},
        completed: const <String>{},
      ),
    ));
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('Complete n1 to unlock this node'), findsOneWidget);
  });
}
