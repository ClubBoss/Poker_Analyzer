import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_filter_service.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  const svc = BoardTextureFilterService();

  test('low paired board matches low and paired filters', () {
    final board = ['2h', '5c', '5d'];
    expect(svc.filter(board, ['low', 'paired']), true);
    expect(svc.filter(board, ['aceHigh']), false);
  });

  test('ace high board matches aceHigh filter only', () {
    final board = ['As', 'Kd', '3c'];
    expect(svc.filter(board, ['aceHigh']), true);
    expect(svc.filter(board, ['low']), false);
  });

  test('isMatch supports suit patterns and exclusions', () {
    final board = [
      CardModel(rank: 'A', suit: '♠'),
      CardModel(rank: '7', suit: '♠'),
      CardModel(rank: '3', suit: '♠'),
    ];
    expect(
      svc.isMatch(board, {'suitPattern': 'monotone', 'excludedRanks': ['K']}),
      true,
    );
    expect(
      svc.isMatch(board, {'requiredRanks': ['K']}),
      false,
    );
  });
}
