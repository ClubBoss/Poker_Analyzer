import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/widgets/skill_tree_node_card.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_list_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SkillTreeNodeModel node(String id, int level) =>
      SkillTreeNodeModel(id: id, title: id, category: 'PF', level: level);

  testWidgets('renders locked and unlocked stages', (tester) async {
    const builder = SkillTreeStageListBuilder();
    final widget = builder.build(
      allNodes: [node('a', 0), node('b', 1)],
      unlockedNodeIds: {'a'},
      completedNodeIds: {},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byType(SkillTreeNodeCard), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('completed stage shows check icon', (tester) async {
    const builder = SkillTreeStageListBuilder();
    final widget = builder.build(
      allNodes: [node('a', 0)],
      unlockedNodeIds: {'a'},
      completedNodeIds: {'a'},
    );
    await tester.pumpWidget(MaterialApp(home: widget));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
