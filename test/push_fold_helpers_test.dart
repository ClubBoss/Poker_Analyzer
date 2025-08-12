import 'package:test/test.dart';
import 'package:poker_analyzer/utils/push_fold.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/action_entry.dart';

void main() {
  test('normalizeAction maps shove/all-in to push', () {
    expect(normalizeAction('shove'), 'push');
    expect(normalizeAction('all-in'), 'push');
    expect(normalizeAction('fold'), 'fold');
  });

  test('actionsForStreet returns [] for OOR', () {
    final spot = TrainingPackSpot(
      id: 's',
      hand: HandData(
        actions: {
          0: [ActionEntry(0, 0, 'push'), ActionEntry(0, 1, 'fold')],
        },
      ),
    );
    final res = actionsForStreet(spot.hand.actions, 5);
    expect(res, isEmpty);
  });

  test('isPushFoldSpot detects hero push and villain fold', () {
    final spot = TrainingPackSpot(
      id: 's',
      hand: HandData(
        heroIndex: 0,
        playerCount: 2,
        actions: {
          0: [ActionEntry(0, 0, 'push'), ActionEntry(0, 1, 'fold')],
        },
      ),
    );
    expect(isPushFoldSpot(spot.hand.actions, 0, 0), isTrue);
  });
}
