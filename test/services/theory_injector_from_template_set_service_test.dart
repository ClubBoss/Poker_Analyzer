import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/training_pack_template_instance_expander_service.dart';
import 'package:poker_analyzer/services/theory_injector_from_template_set_service.dart';

void main() {
  TrainingPackSpot baseSpot() => TrainingPackSpot(
        id: 'base',
        title: 'Base',
        tags: ['init'],
        hand: HandData(
          heroCards: 'Ah Kh',
          position: HeroPosition.btn,
          heroIndex: 0,
          playerCount: 2,
          board: [],
        ),
        board: [],
        meta: {'foo': 'bar'},
      );

  test('creates mini lessons for each generated pack', () {
    final set = TrainingPackTemplateSet(
      baseSpot: baseSpot(),
      variations: [
        ConstraintSet(overrides: {
          'board': [
            ['As', 'Kd', 'Qc'],
            ['2h', '3d', '4c'],
          ],
        }),
      ],
    );

    final expander = TrainingPackTemplateInstanceExpanderService();
    final packs = expander.expand(
      set,
      packIdPrefix: 'pack',
      title: 'Drill',
      tags: ['global'],
      metadata: {'stage': 'level1'},
    );

    final injector = TheoryInjectorFromTemplateSetService(expander: expander);
    final lessons = injector.inject(
      set,
      titlePrefix: 'Lesson: ',
      packIdPrefix: 'pack',
      packTitle: 'Drill',
      tags: ['global'],
      metadata: {'stage': 'level1'},
    );

    expect(lessons, hasLength(packs.length));

    final firstPack = packs.first;
    final firstLesson = lessons.first;
    expect(firstLesson.id, 'theory_${firstPack.id}');
    expect(firstLesson.title, 'Lesson: ${firstPack.title}');
    expect(firstLesson.tags, containsAll(['global', 'init']));
    expect(firstLesson.stage, 'level1');
    expect(firstLesson.linkedPackIds, [firstPack.id]);
    expect(firstLesson.content, isEmpty);
  });
}

