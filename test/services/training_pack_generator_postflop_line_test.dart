import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/training_pack_generator_engine_v2.dart';

void main() {
  test('generate mixes base and postflop line spots', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc', '2h'],
        actions: {
          0: [
            ActionEntry(0, 0, 'raise'),
            ActionEntry(0, 1, 'call'),
          ],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLine: 'cbet-check',
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    expect(spots, hasLength(3));

    final flop = spots.firstWhere((s) => s.street == 1);
    expect(flop.tags, contains('flopCbet'));
    expect(flop.meta['previousActions'], ['raise-call']);

    final turn = spots.firstWhere((s) => s.street == 2);
    expect(turn.tags, containsAll(['flopCbet', 'turnCheck']));
    expect(turn.meta['previousActions'], ['raise-call', 'cbet']);
  });

  test('skips postflop line when board preset mismatches', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc'],
        actions: {
          0: [
            ActionEntry(0, 0, 'raise'),
            ActionEntry(0, 1, 'call'),
          ],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLine: 'cbet-check',
      boardTexturePreset: 'lowPaired',
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    // Only the base spot should remain; line expansion is filtered out.
    expect(spots, hasLength(1));
    expect(spots.first.id, isNotEmpty);
  });

  test('expands postflop line when board preset matches', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', '9d', '4c'],
        actions: {
          0: [
            ActionEntry(0, 0, 'raise'),
            ActionEntry(0, 1, 'call'),
          ],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLine: 'cbet-check',
      boardTexturePreset: 'dryAceHigh',
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    // Base + two street expansions (flop & turn)
    expect(spots, hasLength(3));
  });
}
