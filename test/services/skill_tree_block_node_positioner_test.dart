import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_block_node_positioner.dart';

SkillTreeNodeModel _node(String id) =>
    SkillTreeNodeModel(id: id, title: id, category: 'c');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('positions nodes horizontally with spacing', () {
    final pos = const SkillTreeBlockNodePositioner().calculate(
      nodes: [_node('a'), _node('b')],
      nodeWidth: 100,
      nodeHeight: 50,
      spacing: 10,
    );
    expect(pos['a'], const Rect.fromLTWH(0, 0, 100, 50));
    expect(pos['b'], const Rect.fromLTWH(110, 0, 100, 50));
  });

  test('supports RTL direction', () {
    final pos = const SkillTreeBlockNodePositioner().calculate(
      nodes: [_node('a'), _node('b')],
      nodeWidth: 100,
      nodeHeight: 50,
      spacing: 10,
      direction: TextDirection.rtl,
    );
    expect(pos['b'], const Rect.fromLTWH(0, 0, 100, 50));
    expect(pos['a'], const Rect.fromLTWH(110, 0, 100, 50));
  });

  test('center alignment shifts nodes', () {
    final pos = const SkillTreeBlockNodePositioner().calculate(
      nodes: [_node('x')],
      nodeWidth: 100,
      nodeHeight: 50,
      spacing: 10,
      center: true,
    );
    expect(pos['x'], const Rect.fromLTWH(-50, 0, 100, 50));
  });
}
