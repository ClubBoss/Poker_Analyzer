import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_track_node_stage_marker_service.dart';

void main() {
  final svc = SkillTreeTrackNodeStageMarkerService();

  SkillTreeNodeModel node(String id, int level) =>
      SkillTreeNodeModel(id: id, title: id, category: 'PF', level: level);

  test('groups nodes by level into stage blocks', () {
    final nodes = [node('a', 0), node('b', 1), node('c', 1)];
    final blocks = svc.build(nodes);
    expect(blocks.length, 2);
    expect(blocks.first.stageIndex, 0);
    expect(blocks.first.nodes.map((n) => n.id), ['a']);
    expect(blocks[1].stageIndex, 1);
    expect(blocks[1].nodes.map((n) => n.id), ['b', 'c']);
  });
}
