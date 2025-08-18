import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_track_summary.dart';
import 'package:poker_analyzer/services/tag_mastery_updater.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('updateMastery moves value towards accuracy', () {
    const updater = TagMasteryUpdater();
    final current = {'a': 0.4};
    const summary = TrainingTrackSummary(
      goalId: 'g1',
      accuracy: 80,
      mistakeCount: 2,
      tagBreakdown: {'a': TagSummary(total: 10, correct: 8, accuracy: 80)},
    );

    final updated = updater.updateMastery(current: current, summary: summary);
    // Expected new value = 0.4 + (0.8 - 0.4) * 0.15 = 0.46
    expect(updated['a']!, closeTo(0.46, 0.0001));
  });

  test('new tags start at 0.5', () {
    const updater = TagMasteryUpdater();
    const summary = TrainingTrackSummary(
      goalId: 'g1',
      accuracy: 50,
      mistakeCount: 5,
      tagBreakdown: {'b': TagSummary(total: 4, correct: 2, accuracy: 50)},
    );
    final updated = updater.updateMastery(current: const {}, summary: summary);
    // old default 0.5 -> new = 0.5 + (0.5 - 0.5)*0.15 = 0.5
    expect(updated['b'], 0.5);
  });
}
