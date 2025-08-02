import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/widgets/skill_tree_stage_header_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'cat', level: 1);

  testWidgets('shows hourglass badge when stage in progress', (tester) async {
    const builder = SkillTreeStageHeaderBuilder();
    final header = builder.buildHeader(
      level: 1,
      nodes: [node('a')],
      unlockedNodeIds: {'a'},
      completedNodeIds: {},
    );
    await tester.pumpWidget(MaterialApp(home: header));
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
  });

  testWidgets('shows verified badge when stage perfect', (tester) async {
    const builder = SkillTreeStageHeaderBuilder();
    final header = builder.buildHeader(
      level: 1,
      nodes: [node('a')],
      unlockedNodeIds: {'a'},
      completedNodeIds: {'a'},
    );
    await tester.pumpWidget(MaterialApp(home: header));
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('no badge when overlay provided', (tester) async {
    const builder = SkillTreeStageHeaderBuilder();
    final overlay = const Positioned(right: 0, top: 0, child: Icon(Icons.lock));
    final header = builder.buildHeader(
      level: 1,
      nodes: [node('a')],
      unlockedNodeIds: {'a'},
      completedNodeIds: {},
      overlay: overlay,
    );
    await tester.pumpWidget(MaterialApp(home: header));
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
  });
}
