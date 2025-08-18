import 'package:test/test.dart';
import 'package:poker_analyzer/models/board_stages.dart';
import 'package:poker_analyzer/services/board_filtering_service_v2.dart';

void main() {
  const svc = BoardFilteringServiceV2();

  group('BoardFilteringServiceV2', () {
    test('matches required tags and handles exclusions', () {
      final board = BoardStages(
        flop: ['A♥', 'K♥', 'Q♦'],
        turn: '9♥',
        river: '2♥',
      );

      expect(svc.isMatch(board, {'broadwayHeavy', 'flushDraw'}), isTrue);
      expect(
        svc.isMatch(board, {'broadwayHeavy'}, excludedTags: {'fourToFlush'}),
        isFalse,
      );
      expect(
        svc.isMatch(board, {'broadwayHeavy'}, excludedTags: {'tripleBroadway'}),
        isFalse,
      );
    });

    test('returns false when required tags missing', () {
      final board = BoardStages(
        flop: ['2♣', '3♦', '7♠'],
        turn: '9♥',
        river: 'T♦',
      );
      expect(svc.isMatch(board, {'broadwayHeavy'}), isFalse);
    });
  });
}
