import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/models/training_result.dart';

void main() {
  test('training result json serialization', () {
    final result = TrainingResult(
      date: DateTime.parse('2023-01-01T12:00:00Z'),
      total: 10,
      correct: 8,
      accuracy: 80,
      tags: const ['tag1', 'tag2'],
      notes: 'Some notes',
    );
    final json = result.toJson();
    final copy = TrainingResult.fromJson(json);
    expect(copy.date, result.date);
    expect(copy.total, result.total);
    expect(copy.correct, result.correct);
    expect(copy.accuracy, result.accuracy);
    expect(copy.tags, result.tags);
    expect(copy.notes, result.notes);
  });
}
