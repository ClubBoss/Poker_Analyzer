import 'package:poker_analyzer/l3/jam_fold_evaluator.dart';
import 'package:test/test.dart';

void main() {
  test('custom weights shift decision', () {
    final defaultEval = JamFoldEvaluator();
    final board = FlopBoard.fromString('AsKsQs');
    final outDefault = defaultEval.evaluate(board: board, spr: 2.5);
    expect(outDefault.decision, 'fold');

    final customEval = JamFoldEvaluator.fromWeights({'monotone': 1.0});
    final outCustom = customEval.evaluate(board: board, spr: 2.5);
    expect(outCustom.decision, 'jam');
    expect(outCustom.jamEV, greaterThan(outDefault.jamEV));
  });
}
