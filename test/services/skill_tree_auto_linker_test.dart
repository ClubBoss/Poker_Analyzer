import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/skill_tree_auto_linker.dart';
import 'package:poker_analyzer/services/skill_tag_skill_node_map_service.dart';

void main() {
  test('links spots to unique skill nodes based on tags', () {
    final spots = [
      TrainingPackSpot(id: 's1', tags: ['push']),
      TrainingPackSpot(id: 's2', tags: ['push', 'call']),
      TrainingPackSpot(id: 's3', tags: ['call']),
    ];

    final map = SkillTagSkillNodeMapService(
      map: {'push': 'node_a', 'call': 'node_b'},
    );

    final linker = SkillTreeAutoLinker(map: map);
    linker.linkAll(spots);

    expect(spots[0].meta['skillNode'], 'node_a');
    expect(spots[1].meta['skillNode'], 'node_b');
    expect(spots[2].meta.containsKey('skillNode'), isFalse);
  });

  test('uses the first matching tag', () {
    final spots = [
      TrainingPackSpot(id: 's1', tags: ['unknown', 'call', 'push']),
    ];

    final map = SkillTagSkillNodeMapService(
      map: {'push': 'node_a', 'call': 'node_b'},
    );

    SkillTreeAutoLinker(map: map).linkAll(spots);

    expect(spots[0].meta['skillNode'], 'node_b');
  });
}
