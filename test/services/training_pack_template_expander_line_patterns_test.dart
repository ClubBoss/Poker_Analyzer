import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/line_pattern.dart';
import 'package:poker_analyzer/services/training_pack_template_expander_service.dart';

void main() {
  test('expandLinePatterns converts patterns to spot seeds', () {
    final base = TrainingPackSpot(id: 'base');
    final pattern = LinePattern(
      startingPosition: 'btn',
      streets: {
        'flop': ['villainBet', 'heroCall'],
        'turn': ['villainBet'],
      },
    );
    final set = TrainingPackTemplateSet(
      baseSpot: base,
      linePatterns: [pattern],
    );
    final svc = TrainingPackTemplateExpanderService();
    final seeds = svc.expandLinePatterns(set);
    expect(seeds, hasLength(1));
    final seed = seeds.first;
    expect(seed.position, 'btn');
    expect(seed.villainActions, ['villainBet', 'villainBet']);
    expect(seed.currentStreet, 'turn');
  });
}
