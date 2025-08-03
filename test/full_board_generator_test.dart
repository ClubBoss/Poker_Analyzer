import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/full_board_generator.dart';
import 'package:poker_analyzer/services/board_filtering_service_v2.dart';

void main() {
  test('applies advanced board filtering', () {
    const generator = FullBoardGenerator();
    final boards = generator.generate({
      'requiredRanks': ['A', 'K', 'Q'],
      'rainbow': true,
      'requiredTags': ['broadwayHeavy'],
      'excludedTags': ['fourToFlush'],
    });
    expect(boards, isNotEmpty);
    const svc = BoardFilteringServiceV2();
    for (final b in boards) {
      expect(
        svc.isMatch(b, {'broadwayHeavy'}, excludedTags: {'fourToFlush'}),
        isTrue,
      );
    }
  });
}
