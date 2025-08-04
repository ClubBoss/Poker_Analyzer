import 'package:test/test.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/line_pattern.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/constraint_resolver_v3.dart';

void main() {
  test('resolves hybrid line and board constraints', () {
    final base = TrainingPackSpot(id: 'base', tags: ['base']);
    final set = ConstraintSet(
      boardConstraints: [
        {
          'targetStreet': 'river',
          'requiredRanks': ['A', 'K', 'Q', 'J', 'T'],
          'excludedRanks': ['2', '3', '4', '5', '6', '7', '8', '9'],
          'requiredSuits': ['s'],
          'excludedSuits': ['h', 'd', 'c'],
        }
      ],
      linePattern: LinePattern(
        startingPosition: 'sb',
        streets: {
          'flop': ['villainBet']
        },
      ),
      tags: ['extra'],
    );

    final engine = ConstraintResolverV3();
    final spots = engine.apply(base, [set]);
    expect(spots, isNotEmpty);
    final spot = spots.first;
    expect(spot.templateSourceId, 'base');
    expect(spot.hand.position, HeroPosition.sb);
    expect(spot.villainAction, 'villainBet');
    expect(spot.board.length, 5);
    expect(spot.tags, containsAll(['base', 'extra', 'flopVillainBet']));
  });
}
