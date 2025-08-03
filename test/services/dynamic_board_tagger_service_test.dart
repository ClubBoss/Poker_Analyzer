import 'package:test/test.dart';
import 'package:poker_analyzer/services/dynamic_board_tagger_service.dart';
import 'package:poker_analyzer/models/card_model.dart';

void main() {
  const svc = DynamicBoardTaggerService();

  test('tags dry ace high rainbow board', () {
    final board = [
      CardModel(rank: 'A', suit: '♠'),
      CardModel(rank: 'K', suit: '♦'),
      CardModel(rank: '3', suit: '♣'),
    ];
    final tags = svc.tagBoard(board);
    expect(tags.contains('aceHigh'), true);
    expect(tags.contains('rainbow'), true);
    expect(tags.contains('dry'), true);
    expect(tags.contains('wet'), false);
  });

  test('tags wet connected monotone board', () {
    final board = [
      CardModel(rank: '9', suit: '♣'),
      CardModel(rank: 'T', suit: '♣'),
      CardModel(rank: 'J', suit: '♣'),
    ];
    final tags = svc.tagBoard(board);
    expect(tags.contains('monotone'), true);
    expect(tags.contains('connected'), true);
    expect(tags.contains('wet'), true);
  });

  test('tags low paired board', () {
    final board = [
      CardModel(rank: '2', suit: '♥'),
      CardModel(rank: '5', suit: '♣'),
      CardModel(rank: '5', suit: '♦'),
    ];
    final tags = svc.tagBoard(board);
    expect(tags.containsAll(['low', 'paired']), true);
    expect(tags.contains('rainbow'), true);
  });
}

