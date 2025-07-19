import 'package:test/test.dart';
import 'package:poker_analyzer/core/training/generation/board_similarity_engine.dart';

void main() {
  test('getSimilarFlop returns alternative flop', () {
    const engine = BoardSimilarityEngine();
    final res = engine.getSimilarFlop(['4h', '5d', '6s']);
    expect(res.length, 3);
    expect(res, isNot(equals(['4h', '5d', '6s'])));
  });
}
