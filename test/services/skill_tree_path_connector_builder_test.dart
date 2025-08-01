import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_path_connector_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = SkillTreePathConnectorBuilder();

  SkillTreeNodeModel node(String id) =>
      SkillTreeNodeModel(id: id, title: id, category: 'PF');

  testWidgets('builds connector widgets for nodes', (tester) async {
    final nodes = [node('a'), node('b'), node('c')];
    final bounds = {
      'a': const Rect.fromLTWH(0, 0, 20, 20),
      'b': const Rect.fromLTWH(40, 0, 20, 20),
      'c': const Rect.fromLTWH(80, 0, 20, 20),
    };
    final connectors = builder.build(
      nodes: nodes,
      bounds: bounds,
      unlockedNodeIds: {'a', 'b', 'c'},
    );
    await tester.pumpWidget(MaterialApp(home: Stack(children: connectors)));
    expect(find.byType(CustomPaint), findsNWidgets(2));
  });
}
