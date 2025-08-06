import 'dart:math';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/open_limped_spot_template_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  test('generates limp spot template sets with metadata', () {
    final service =
        OpenLimpedSpotTemplateGeneratorService(random: Random(1));
    final sets = service.generate(
      effectiveStack: 20,
      heroRange: 'pockets',
      bbResponseTendencies: const {'raiseFreq': 0.3},
    );
    expect(sets.length, inInclusiveRange(5, 10));
    final tpl = sets.first.template;
    expect(tpl.tags, containsAll(['preflop', 'limp', 'sbvsbb', 'LevelII']));
    expect(tpl.meta['level'], 2);
    expect(tpl.meta['topic'], 'SB limp');
    final spot = tpl.spots.first;
    expect(spot.villainAction, 'limp');
    expect(spot.heroOptions, containsAll(['isoRaise', 'check']));
    expect(spot.hand.position, HeroPosition.bb);
    expect(spot.hand.stacks['0'], 20);
  });
}

