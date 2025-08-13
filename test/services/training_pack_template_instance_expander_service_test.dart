import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/training_pack_template_instance_expander_service.dart';

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

  test('expands set into one-pack-per-spot', () {
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
    final svc = TrainingPackTemplateInstanceExpanderService();
    final packs = svc.expand(
      set,
      packIdPrefix: 'pack',
      title: 'Drill',
      tags: ['global'],
      metadata: {'shared': 1},
    );
    expect(packs, hasLength(2));
    final first = packs.first;
    expect(first.id, 'pack_1');
    expect(first.title, 'Drill - As Kd Qc');
    expect(first.tags, containsAll(['global', 'init']));
    expect(first.metadata['shared'], 1);
    expect(first.metadata['foo'], 'bar');
    expect(first.spots, hasLength(1));
  });
}
