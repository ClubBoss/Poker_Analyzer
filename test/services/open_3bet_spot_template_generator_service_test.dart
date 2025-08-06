import 'dart:math';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/open_3bet_spot_template_generator_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  test('generates 3bet push templates with metadata', () {
    final service = Open3betSpotTemplateGeneratorService(random: Random(1));
    final templates = service.generate(
      heroPosition: HeroPosition.sb,
      villainPosition: HeroPosition.co,
      effectiveStack: 25,
      heroRange: 'pockets',
      villainRange: 'top20',
    );
    expect(templates.length, inInclusiveRange(5, 10));
    final tpl = templates.first;
    expect(tpl.tags, containsAll(['preflop', '3bet', 'LevelII']));
    expect(tpl.meta['level'], 2);
    expect(tpl.meta['topic'], '3bet push');
    final spot = tpl.spots.first;
    expect(spot.villainAction, 'open 2.5');
    expect(spot.heroOptions, contains('3betPush'));
    expect(spot.hand.position, HeroPosition.sb);
    expect(spot.hand.stacks['0'], 25);
  });
}
