import 'package:test/test.dart';

import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';
import 'package:poker_analyzer/services/training_pack_template_expander_service.dart';

void main() {
  test('expand generates spots preserving tags and theory link', () {
    final base = TrainingPackSpot(
      id: 'base',
      hand: HandData.fromSimpleInput('Ah Kh', HeroPosition.btn, 30),
      tags: ['theory'],
    )..theoryLink = InlineTheoryLink(title: 'lesson', onTap: () {});

    final set = TrainingPackTemplateSet(
      baseSpot: base,
      variations: [
        {
          'board': [
            ['As', 'Kd', 'Qc'],
            ['7h', '7d', '2c'],
          ],
          'heroStack': [10, 20],
          'tags': [
            ['cbet'],
          ],
        }
      ],
    );

    final expander = const TrainingPackTemplateExpanderService();
    final spots = expander.expand(set);

    expect(spots, hasLength(4));
    for (final s in spots) {
      expect(s.templateSourceId, 'base');
      expect(s.tags, containsAll(['theory', 'cbet']));
      expect(s.theoryLink?.title, 'lesson');
    }

    final boards = spots.map((s) => s.board.join(','));
    expect(boards.toSet(), {'As,Kd,Qc', '7h,7d,2c'});

    final stacks = spots.map((s) => s.hand.stacks['0']);
    expect(stacks.toSet(), {10.0, 20.0});
  });
}
