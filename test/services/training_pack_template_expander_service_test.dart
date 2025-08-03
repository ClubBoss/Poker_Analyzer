import 'package:test/test.dart';

import 'package:poker_analyzer/models/training_pack_template_set.dart';
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
}
