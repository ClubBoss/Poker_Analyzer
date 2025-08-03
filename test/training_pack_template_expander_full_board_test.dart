import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/training_pack_template_expander_service.dart';

void main() {
  test('expands board constraints into full boards', () {
    final base = TrainingPackSpot(id: 'base');
    final variation = ConstraintSet(
      overrides: {
        'boardConstraints': [
          {
            'paired': true,
            'aceHigh': true,
            'rainbow': true,
            'drawy': true,
            'requiredRanks': ['A', 'K'],
            'requiredSuits': ['♠', '♥', '♦'],
          }
        ]
      },
    );
    final set = TrainingPackTemplateSet(baseSpot: base, variations: [variation]);
    final svc = TrainingPackTemplateExpanderService();
    final spots = svc.expand(set);
    // Should expand to all generated boards.
    expect(spots.length, 6 * 1176);
    // Each spot's board should have five cards.
    expect(spots.every((s) => s.board.length == 5), isTrue);
  });
}
