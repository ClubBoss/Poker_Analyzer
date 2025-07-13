import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/undo_history/diff_engine.dart';

void main() {
  test('diff round trip', () {
    final engine = DiffEngine();
    final a = {
      'a': 1,
      'b': {'c': 2, 'd': 3},
    };
    final b = {
      'a': 2,
      'b': {'c': 2, 'd': 4},
    };
    final diff = engine.compute(a, b);
    final forward = engine.apply(a, diff.forward);
    expect(forward['a'], 2);
    expect((forward['b'] as Map)['d'], 4);
    final back = engine.apply(forward, diff.backward);
    expect(back['a'], 1);
    expect((back['b'] as Map)['d'], 3);
  });
}
