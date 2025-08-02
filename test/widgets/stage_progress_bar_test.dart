import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/skill_tree.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/widgets/stage_progress_bar.dart';

void main() {
  SkillTree buildTree() {
    final nodes = {
      'a': const SkillTreeNodeModel(
        id: 'a',
        title: 'A',
        category: 'PF',
        level: 1,
      ),
      'b': const SkillTreeNodeModel(
        id: 'b',
        title: 'B',
        category: 'PF',
        level: 1,
        prerequisites: ['a'],
      ),
      'c': const SkillTreeNodeModel(
        id: 'c',
        title: 'C',
        category: 'PF',
        level: 2,
        prerequisites: ['b'],
      ),
    };
    return SkillTree(nodes: nodes);
  }

  testWidgets('shows progress for current stage', (tester) async {
    final tree = buildTree();
    await tester.pumpWidget(
      MaterialApp(
        home: StageProgressBar(tree: tree, completedNodeIds: {'a'}),
      ),
    );
    expect(find.text('Этап 1: 1 из 2'), findsOneWidget);
  });

  testWidgets('moves to next stage when unlocked', (tester) async {
    final tree = buildTree();
    await tester.pumpWidget(
      MaterialApp(
        home: StageProgressBar(tree: tree, completedNodeIds: {'a', 'b'}),
      ),
    );
    expect(find.text('Этап 2: 0 из 1'), findsOneWidget);
  });
}
