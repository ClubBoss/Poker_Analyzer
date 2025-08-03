import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/board_stages.dart';
import 'package:poker_analyzer/services/training_pack_template_expander_service.dart';
import 'package:poker_analyzer/services/board_filtering_service_v2.dart';

void main() {
  test('expands board constraints with tag filters to river', () {
    final base = TrainingPackSpot(id: 'base');
    final variation = ConstraintSet(
      overrides: {
        'boardConstraints': [
          {
            'targetStreet': 'river',
            'requiredRanks': ['A', 'K', 'Q', 'J', 'T'],
            'requiredTags': ['broadwayHeavy'],
            'excludedTags': ['paired'],
          }
        ]
      },
    );
    final set = TrainingPackTemplateSet(baseSpot: base, variations: [variation]);
    final svc = TrainingPackTemplateExpanderService();
    final spots = svc.expand(set);
    expect(spots, isNotEmpty);
    final filter = const BoardFilteringServiceV2();
    for (final s in spots) {
      expect(s.board.length, 5);
      final stages = BoardStages(
        flop: s.board.take(3).toList(),
        turn: s.board[3],
        river: s.board[4],
      );
      expect(
        filter.isMatch(stages, {'broadwayHeavy'}, excludedTags: {'paired'}),
        isTrue,
      );
      final ranks = s.board.map((c) => c[0]).toSet();
      expect(ranks.containsAll({'A', 'K', 'Q', 'J', 'T'}), isTrue);
    }
  });
}
