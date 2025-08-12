import 'package:test/test.dart';
import 'package:poker_analyzer/utils/push_fold.dart';
import 'package:poker_analyzer/models/action_entry.dart';

void main() {
  test('normalizeAction maps shove/all-in to push', () {
    expect(normalizeAction('shove'), 'push');
    expect(normalizeAction('all-in'), 'push');
    expect(normalizeAction('fold'), 'fold');
  });

  test('actionsForStreet returns [] for OOR', () {
    final actions = {
      0: [ActionEntry(0, 0, 'push'), ActionEntry(0, 1, 'fold')],
    };
    final res = actionsForStreet(actions, 5);
    expect(res, isEmpty);
  });

  test('isPushFoldSpot detects hero push and villain fold', () {
    final actions = {
      0: [ActionEntry(0, 0, 'push'), ActionEntry(0, 1, 'fold')],
    };
    expect(isPushFoldSpot(actions, 0, 0), isTrue);
  });
}
