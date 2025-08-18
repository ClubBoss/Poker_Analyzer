import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/training_pack_template_set_expander_service.dart';

void main() {
  TrainingPackSpot baseSpot() => TrainingPackSpot(
    id: 'base',
    hand: HandData(
      heroCards: 'Ah Kh',
      position: HeroPosition.btn,
      heroIndex: 0,
      playerCount: 2,
      board: [],
    ),
    board: [],
  );

  test('expands multiple variations', () {
    final set = TrainingPackTemplateSet(
      baseSpot: baseSpot(),
      variations: [
        ConstraintSet(
          overrides: {
            'board': [
              ['As', 'Kd', 'Qc'],
              ['7h', '7d', '2c'],
            ],
            'heroStack': [10, 20],
          },
        ),
      ],
    );
    final svc = TrainingPackTemplateSetExpanderService();
    final spots = svc.expand(set);
    expect(spots, hasLength(4));
  });

  test('filters by required clusters', () {
    final set = TrainingPackTemplateSet(
      baseSpot: baseSpot(),
      variations: [
        ConstraintSet(
          overrides: {
            'board': [
              ['As', 'Kd', 'Qc'],
              ['2h', '3d', '4c'],
            ],
          },
        ),
      ],
      requiredBoardClusters: ['broadway-heavy'],
    );
    final svc = TrainingPackTemplateSetExpanderService();
    final spots = svc.expand(set);
    expect(spots, hasLength(1));
    expect(spots.first.board.join(','), 'As,Kd,Qc');
  });

  test('filters by excluded clusters', () {
    final set = TrainingPackTemplateSet(
      baseSpot: baseSpot(),
      variations: [
        ConstraintSet(
          overrides: {
            'board': [
              ['As', 'Kd', 'Qc'],
              ['2h', '3d', '4c'],
            ],
          },
        ),
      ],
      excludedBoardClusters: ['broadway-heavy'],
    );
    final svc = TrainingPackTemplateSetExpanderService();
    final spots = svc.expand(set);
    expect(spots, hasLength(1));
    expect(spots.first.board.join(','), '2h,3d,4c');
  });

  test('returns base spot when no variations', () {
    final set = TrainingPackTemplateSet(baseSpot: baseSpot());
    final svc = TrainingPackTemplateSetExpanderService();
    final spots = svc.expand(set);
    expect(spots, hasLength(1));
    expect(spots.first.id, 'base');
  });
}
