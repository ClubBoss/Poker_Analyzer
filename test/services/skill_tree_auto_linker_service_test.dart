import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/skill_tree_auto_linker_service.dart';

void main() {
  group('SkillTreeAutoLinkerService', () {
    test('links nodes to packs and lessons by tags', () {
      final nodes = [
        SkillTreeNode(id: 'n1', tags: ['push']),
        SkillTreeNode(id: 'n2', tags: ['call']),
      ];

      final packs = [
        TrainingPackModel(
          id: 'p1',
          title: 'Pack1',
          spots: [
            TrainingPackSpot(id: 's1', tags: ['push']),
            TrainingPackSpot(id: 's2', tags: ['call']),
          ],
        ),
        TrainingPackModel(
          id: 'p2',
          title: 'Pack2',
          spots: [TrainingPackSpot(id: 's3', tags: ['raise'])],
          tags: const ['misc'],
        ),
      ];

      final lessons = [
        TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '', tags: ['push']),
        TheoryMiniLessonNode(id: 'l2', title: 'L2', content: '', tags: ['raise']),
      ];

      final service = const SkillTreeAutoLinkerService();
      final res = service.link(nodes, packs, lessons);

      expect(res['n1']!.packIds, ['p1']);
      expect(res['n1']!.lessonIds, ['l1']);
      expect(nodes[0].meta['linkedPackIds'], ['p1']);
      expect(nodes[0].meta['linkedLessonIds'], ['l1']);

      expect(res['n2']!.packIds, ['p1']);
      expect(res['n2']!.lessonIds, isEmpty);
    });
  });
}
