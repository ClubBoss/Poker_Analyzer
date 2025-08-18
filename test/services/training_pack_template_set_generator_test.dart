import 'package:test/test.dart';

import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/services/training_pack_template_variation_generator.dart';

void main() {
  test('generator produces distinct template variations', () {
    final baseSpot = TrainingPackSpot(
      id: 's1',
      hand: HandData(
        heroCards: 'As Ks',
        position: HeroPosition.btn,
        stacks: {'0': 20.0, '1': 20.0},
        playerCount: 2,
      ),
    );

    final set = TrainingPackTemplateSet(
      baseSpot: baseSpot,
      playerTypeVariations: const ['reg', 'fish'],
      suitAlternation: true,
      stackDepthMods: const [1, -1],
    );

    final baseTemplate = TrainingPackTemplateV2(
      id: 'tpl',
      name: 'Base',
      trainingType: TrainingType.pushFold,
      spots: [],
      spotCount: 0,
      dynamicSpots: const [],
      gameType: GameType.cash,
      bb: 20,
      positions: const ['btn'],
    );

    final gen = TrainingPackTemplateSetGenerator();
    final templates = gen.generate(base: baseTemplate, set: set);

    expect(templates, hasLength(8));
    // Unique ids
    expect(templates.map((t) => t.id).toSet().length, 8);

    // Stack depth mods applied
    final bbValues = templates.map((t) => t.bb).toSet();
    expect(bbValues, {21, 19});

    // Player type variations
    final pTypes = templates
        .map((t) => t.spots.first.meta['playerType'])
        .toSet();
    expect(pTypes, {'reg', 'fish'});

    // Suit alternation
    final heroCards = templates
        .map((t) => t.spots.first.hand.heroCards)
        .toSet();
    expect(heroCards, {'As Ks', 'As Kh'});
  });
}
