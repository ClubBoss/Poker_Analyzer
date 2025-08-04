import 'package:test/test.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/services/training_pack_template_expander_service.dart';

void main() {
  test('expandLines builds seeds from line patterns', () {
    const yaml = '''
baseSpot:
  id: base
linePatterns:
  - startingPosition: btn
    streets:
      flop: [villainBet, heroCall]
      turn: [check]
''';
    final set = TrainingPackTemplateSet.fromYaml(yaml);
    final svc = TrainingPackTemplateExpanderService();
    final seeds = svc.expandLines(set);
    expect(seeds, hasLength(1));
    final seed = seeds.first;
    expect(seed.position, 'btn');
    expect(seed.villainActions, ['villainBet']);
  });
}
