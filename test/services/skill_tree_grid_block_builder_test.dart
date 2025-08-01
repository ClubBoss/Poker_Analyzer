import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/widgets/skill_tree_grid_block_builder.dart';
import 'package:poker_analyzer/widgets/skill_tree_node_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'PF', level: 1);

  testWidgets('builds grid block with nodes and connectors', (tester) async {
    final builder = const SkillTreeGridBlockBuilder();
    final widget = builder.build(
      level: 1,
      nodes: [node('a'), node('b')],
      unlockedNodeIds: {'a', 'b'},
      completedNodeIds: {'a'},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byType(SkillTreeNodeCard), findsNWidgets(2));
    // Only one connector between two nodes
    expect(find.byType(CustomPaint), findsOneWidget);
  });
}
