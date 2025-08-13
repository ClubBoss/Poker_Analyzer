import 'package:poker_analyzer/l3/jam_fold_evaluator.dart';
import 'package:test/test.dart';

void main() {
  final evaluator = JamFoldEvaluator();

  test('monotone broadway high SPR -> fold', () {
    final board = FlopBoard.fromString('AsKsQs');
    final out = evaluator.evaluate(board: board, spr: 2.5);
    expect(out.decision, 'fold');
  });

  test('rainbow unpaired low SPR -> jam', () {
    final board = FlopBoard.fromString('AsKd7c');
    final out = evaluator.evaluate(board: board, spr: 0.8);
    expect(out.decision, 'jam');
  });

  test('twoTone ace-high mid SPR -> jam', () {
    final board = FlopBoard.fromString('AsKd9d');
    final out = evaluator.evaluate(board: board, spr: 1.5);
    expect(out.decision, 'jam');
  });
}
