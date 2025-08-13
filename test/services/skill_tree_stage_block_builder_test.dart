import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/widgets/skill_tree_node_card.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_block_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'PF', level: 1);

  testWidgets('locked stage hides nodes and shows lock overlay',
      (tester) async {
    const builder = SkillTreeStageBlockBuilder();
    final widget = builder.build(
      level: 1,
      nodes: [node('a')],
      unlockedNodeIds: {},
      completedNodeIds: {},
      justUnlockedNodeIds: const {},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byType(SkillTreeNodeCard), findsNothing);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('completed stage shows check overlay', (tester) async {
    const builder = SkillTreeStageBlockBuilder();
    final widget = builder.build(
      level: 1,
      nodes: [node('a')],
      unlockedNodeIds: {'a'},
      completedNodeIds: {'a'},
      justUnlockedNodeIds: const {},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byType(SkillTreeNodeCard), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
