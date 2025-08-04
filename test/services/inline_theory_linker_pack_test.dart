import 'package:flutter_test/flutter_test.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';

void main() {
  test('linkPack adds inlineLessonId based on tags', () {
    final pack = TrainingPackTemplateV2(
      id: 'p1',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      spots: [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet']),
        TrainingPackSpot(id: 's2', hand: HandData(), tags: ['probe']),
        TrainingPackSpot(
          id: 's3',
          hand: HandData(),
          tags: ['cbet'],
          inlineLessonId: 'existing',
        ),
      ],
    );

    const lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'CBet',
        content: '',
        tags: ['cbet'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'Probe',
        content: '',
        tags: ['probe'],
      ),
    ];

    InlineTheoryLinker.linkPack(pack, lessons);

    expect(pack.spots[0].inlineLessonId, 'l1');
    expect(pack.spots[1].inlineLessonId, 'l2');
    // Existing ID should remain untouched
    expect(pack.spots[2].inlineLessonId, 'existing');
  });
}
