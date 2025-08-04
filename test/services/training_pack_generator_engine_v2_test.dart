import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/line_pattern.dart';
import 'package:poker_analyzer/services/training_pack_generator_engine_v2.dart';

void main() {
  test('generate combines board and line expansions', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData.fromSimpleInput('AhAd', HeroPosition.btn, 10),
      tags: ['base'],
    );
    final variation = ConstraintSet(
      overrides: {
        'board': [
          ['As', 'Kd', 'Qc']
        ]
      },
    );
    final pattern = LinePattern(
      startingPosition: 'sb',
      streets: {
        'flop': ['villainBet']
      },
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      variations: [variation],
      linePatterns: [pattern],
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);
    expect(spots.length, 2);
    final lineSpot =
        spots.firstWhere((s) => s.tags.contains('flopVillainBet'));
    expect(lineSpot.templateSourceId, 'base');
    expect(lineSpot.hand.position, HeroPosition.sb);
    expect(lineSpot.villainAction, 'villainBet');
    expect(lineSpot.street, 1);
    expect(
      lineSpot.tags,
      containsAll(['base', 'flopVillainBet', 'SB', 'HU', '10bb', 'flop']),
    );
  });
}
