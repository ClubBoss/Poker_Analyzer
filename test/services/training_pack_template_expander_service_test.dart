import 'package:test/test.dart';

import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/auto_spot_theory_injector_service.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';
import 'package:poker_analyzer/services/training_pack_template_expander_service.dart';

class _Linker extends InlineTheoryLinker {
  _Linker();

  @override
  InlineTheoryLink? getLink(List<String> theoryTags) =>
      InlineTheoryLink(title: 'lesson', onTap: () {});
}

void main() {
  test('expand generates spots and injects theory link', () {
    const yaml = '''
baseSpot:
  id: base
  hand:
    heroCards: Ah Kh
    position: btn
    heroIndex: 0
    playerCount: 2
    board: []
  tags: [theory]
variations:
  - overrides:
      board:
        - [As, Kd, Qc]
        - [7h, 7d, 2c]
      heroStack: [10, 20]
    tags: [cbet]
''';

    final set = TrainingPackTemplateSet.fromYaml(yaml);
    final expander = TrainingPackTemplateExpanderService(
      injector: AutoSpotTheoryInjectorService(linker: _Linker()),
    );
    final spots = expander.expand(set);

    expect(spots, hasLength(4));
    for (final s in spots) {
      expect(s.templateSourceId, 'base');
      expect(s.tags, containsAll(['theory', 'cbet']));
      expect(s.theoryLink?.title, 'lesson');
    }

    final boards = spots.map((s) => s.board.join(',')).toSet();
    expect(boards, {'As,Kd,Qc', '7h,7d,2c'});

    final stacks = spots.map((s) => s.hand.stacks['0']).toSet();
    expect(stacks, {10.0, 20.0});
  });

  test('expands board preset and merges overrides', () {
    const yaml = '''
baseSpot:
  id: base
  hand:
    heroCards: Ah Kh
    position: btn
    heroIndex: 0
    playerCount: 2
    board: []
variations:
  - boardConstraints:
      - preset: lowPaired
        requiredTextures: [paired, low, monotone]
''';

    final set = TrainingPackTemplateSet.fromYaml(yaml);
    final svc = TrainingPackTemplateExpanderService();
    final spots = svc.expand(set);
    expect(spots, isNotEmpty);
    const lowRanks = {'2', '3', '4', '5', '6', '7', '8'};
    for (final s in spots) {
      expect(s.board.length, 5);
      final suits = s.board.take(3).map((c) => c[1]).toSet();
      expect(suits.length, 1); // monotone override applied
      final ranks = s.board.take(2).map((c) => c[0]).toSet();
      expect(ranks.length, 1); // paired
      expect(lowRanks.containsAll(s.board.take(3).map((c) => c[0])), isTrue);
    }
  });

  test('filters out spots that fail constraint checks', () {
    const yaml = '''
baseSpot:
  id: base
  hand:
    heroCards: Ah Kh
    position: btn
    heroIndex: 0
    playerCount: 2
    board: []
variations:
  - positions: [co]
    overrides:
      heroStack: [20]
    minStack: 25
''';

    final set = TrainingPackTemplateSet.fromYaml(yaml);
    final svc = TrainingPackTemplateExpanderService();
    final spots = svc.expand(set);
    expect(spots, isEmpty);
  });

  test('retains base spot when board cluster matches', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'Ah Kh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc'],
      ),
      board: ['As', 'Kd', 'Qc'],
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      requiredBoardClusters: ['broadway-heavy'],
    );
    final svc = TrainingPackTemplateExpanderService();
    final spots = svc.expand(set);
    expect(spots, hasLength(1));
  });

  test('drops base spot when board cluster excluded', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData(
        heroCards: 'Ah Kh',
        position: HeroPosition.btn,
        board: ['As', 'Kd', 'Qc'],
      ),
      board: ['As', 'Kd', 'Qc'],
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      excludedBoardClusters: ['broadway-heavy'],
    );
    final svc = TrainingPackTemplateExpanderService();
    final spots = svc.expand(set);
    expect(spots, isEmpty);
  });
}
