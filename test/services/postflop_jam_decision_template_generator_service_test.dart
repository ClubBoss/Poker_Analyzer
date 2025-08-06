import 'dart:math';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/postflop_jam_decision_template_generator_service.dart';

void main() {
  test('generates river jam decision templates with metadata', () {
    final service =
        PostflopJamDecisionTemplateGeneratorService(random: Random(1));
    final templates = service.generate(
      boardTexture: 'rainbow',
      heroHandGroup: 'pockets',
      villainLine: 'bet bet jam',
      effectiveStack: 40,
      potSize: 20,
    );
    expect(templates.length, inInclusiveRange(5, 10));
    final tpl = templates.first;
    expect(tpl.tags, containsAll(['river', 'jam', 'call', 'potOdds']));
    expect(tpl.meta['level'], 'intermediate/advanced');
    expect(tpl.meta['goal'], 'riverDecision');
    expect(tpl.meta['theme'], 'postflop');
    final spot = tpl.spots.first;
    expect(spot.tags, contains('jam'));
    expect(spot.hand.stacks['0'], 40);
    expect(spot.hand.board.length, 5);
    expect(
      spot.heroOptions,
      anyOf(
        equals(['call', 'fold']),
        equals(['shove', 'fold']),
      ),
    );
  });
}
