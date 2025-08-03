import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/helpers/board_filtering_params_builder.dart';
import 'package:poker_analyzer/services/full_board_generator_service.dart';

void main() {
  test('build generates filter and generator respects it', () {
    final params = BoardFilteringParamsBuilder.build([
      'aceHigh',
      'paired',
      'rainbow',
    ]);
    expect(params['boardTexture'], containsAll(['aceHigh', 'paired']));
    expect(params['suitPattern'], 'rainbow');

    final svc = FullBoardGeneratorService(random: Random(42));
    final board = svc.generateBoard(
      FullBoardRequest(stages: 3, boardFilterParams: params),
    );

    expect(board.flop.length, 3);
    expect(board.flop.any((c) => c.rank == 'A'), isTrue);
    final ranks = board.flop.map((c) => c.rank).toList();
    expect(ranks.toSet().length, lessThan(ranks.length));
    expect(board.flop.map((c) => c.suit).toSet().length, 3);
  });

  test('aliases are resolved via tag library', () {
    final params = BoardFilteringParamsBuilder.build([
      'two-tone',
      'acehigh',
      'drawy',
    ]);
    expect(params['suitPattern'], 'twoTone');
    expect(params['boardTexture'], contains('aceHigh'));
    expect(params['boardTexture'], contains('straightDrawHeavy'));
  });

  test('throws on unknown tag', () {
    expect(
      () => BoardFilteringParamsBuilder.build(['unknown']),
      throwsArgumentError,
    );
  });

  test('highCard tag generates board with high card', () {
    final params = BoardFilteringParamsBuilder.build(['highCard']);
    final svc = FullBoardGeneratorService(random: Random(7));
    final board = svc.generateBoard(
      FullBoardRequest(stages: 3, boardFilterParams: params),
    );
    expect(board.flop.any((c) => ['T', 'J', 'Q', 'K', 'A'].contains(c.rank)),
        isTrue);
  });
}
