import 'package:test/test.dart';

import 'package:poker_analyzer/models/summary_result.dart';

void main() {
  test('SummaryResult JSON round-trip', () {
    final original = SummaryResult(
      totalHands: 100,
      correct: 60,
      incorrect: 40,
      accuracy: 60.0,
      mistakeTagFrequencies: {'bluff': 3},
      streetBreakdown: {'flop': 5},
      positionMistakeFrequencies: {'UTG': 2},
      accuracyPerSession: {1: 55.0},
    );
    final json = original.toJson();
    final copy = SummaryResult.fromJson(json);
    expect(copy.totalHands, original.totalHands);
    expect(copy.correct, original.correct);
    expect(copy.incorrect, original.incorrect);
    expect(copy.accuracy, closeTo(original.accuracy, 1e-9));
    expect(copy.mistakeTagFrequencies, original.mistakeTagFrequencies);
    expect(copy.streetBreakdown, original.streetBreakdown);
    expect(
      copy.positionMistakeFrequencies,
      original.positionMistakeFrequencies,
    );
    expect(copy.accuracyPerSession, original.accuracyPerSession);
  });
}
