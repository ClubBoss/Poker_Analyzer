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
}
