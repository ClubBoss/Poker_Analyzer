import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/postflop_line.dart';
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
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
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
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
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
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
      boardTexturePreset: 'dryAceHigh',
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    // Base + two street expansions (flop & turn)
    expect(spots, hasLength(3));
  });

  test('skips postflop line when board matches excluded preset', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', '9d', '4c'],
        actions: {
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
      excludeBoardTexturePresets: ['aceHigh'],
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    // Only the base spot should remain; line expansion is filtered out.
    expect(spots, hasLength(1));
    expect(spots.first.id, isNotEmpty);
  });

  test('skips postflop line when required cluster mismatches', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', '9d', '4c'],
        actions: {
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
      requiredBoardClusters: ['wet'],
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    expect(spots, hasLength(1));
  });

  test('expands postflop line when required cluster matches', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc'],
        actions: {
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
      requiredBoardClusters: ['wet'],
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    expect(spots, hasLength(3));
  });

  test('skips postflop line when board matches excluded cluster', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc'],
        actions: {
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [PostflopLine(line: 'cbet-check')],
      excludedBoardClusters: ['wet'],
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    expect(spots, hasLength(1));
  });

  test('expands multiple postflop lines into combined spots', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc', '2h'],
        actions: {
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [
        PostflopLine(line: 'cbet-check'),
        PostflopLine(line: 'check'),
      ],
      expandAllLines: true,
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    // Base + three expansions (two from first line, one from second)
    expect(spots, hasLength(4));

    final altFlop = spots.where(
      (s) => s.street == 1 && s.tags.contains('flopCheck'),
    );
    expect(altFlop.length, 1);
  });

  test('selects weighted postflop line deterministically', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'AhKh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc', '2h'],
        actions: {
          0: [ActionEntry(0, 0, 'raise'), ActionEntry(0, 1, 'call')],
        },
      ),
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      postflopLines: [
        PostflopLine(line: 'cbet-check', weight: 2),
        PostflopLine(line: 'check', weight: 1),
      ],
      postflopLineSeed: 1,
    );

    final engine = TrainingPackGeneratorEngineV2();
    final spots = engine.generate(set);

    // Only one of the lines should be expanded.
    expect(spots.length, 3);
    final hasCbet = spots.any((s) => s.tags.contains('flopCbet'));
    final hasCheck = spots.any((s) => s.tags.contains('flopCheck'));
    expect(hasCbet ^ hasCheck, isTrue);
  });
}
