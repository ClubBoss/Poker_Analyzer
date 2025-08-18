import 'package:test/test.dart';

import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/services/board_cluster_constraint_engine.dart';

void main() {
  group('BoardClusterConstraintEngine.matches', () {
    final board = [
      CardModel(rank: 'A', suit: 's'),
      CardModel(rank: 'K', suit: 'd'),
      CardModel(rank: 'Q', suit: 'c'),
    ];

    test('returns true when constraints satisfied', () {
      expect(
        BoardClusterConstraintEngine.matches(
          board: board,
          requiredClusters: ['broadway-heavy'],
        ),
        isTrue,
      );
    });

    test('fails when required cluster missing', () {
      expect(
        BoardClusterConstraintEngine.matches(
          board: board,
          requiredClusters: ['trap'],
        ),
        isFalse,
      );
    });

    test('fails when excluded cluster present', () {
      expect(
        BoardClusterConstraintEngine.matches(
          board: board,
          excludedClusters: ['broadway-heavy'],
        ),
        isFalse,
      );
    });

    test('is case insensitive', () {
      expect(
        BoardClusterConstraintEngine.matches(
          board: board,
          requiredClusters: ['BROADWAY-HEAVY'],
        ),
        isTrue,
      );
    });

    test('handles empty requirements', () {
      expect(BoardClusterConstraintEngine.matches(board: board), isTrue);
    });
  });
}
