import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_result.dart';
import 'package:poker_analyzer/services/weakness_cluster_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects weakest tags', () {
    final results = [
      TrainingResult(
          date: DateTime.now(),
          total: 10,
          correct: 6,
          accuracy: 60,
          tags: const ['a'],
          evDiff: -1),
      TrainingResult(
          date: DateTime.now(),
          total: 8,
          correct: 8,
          accuracy: 100,
          tags: const ['b'],
          evDiff: 0.2),
      TrainingResult(
          date: DateTime.now(),
          total: 5,
          correct: 3,
          accuracy: 60,
          tags: const ['a'],
          evDiff: -0.5),
    ];

    final mastery = {'a': 0.5, 'b': 0.9};

    const engine = WeaknessClusterEngine();
    final clusters =
        engine.detectWeaknesses(results: results, tagMastery: mastery);

    expect(clusters.first.tag, 'a');
    expect(clusters.first.reason.isNotEmpty, true);
    expect(clusters.first.severity, greaterThan(0));
    final top =
        engine.topWeaknesses(results: results, tagMastery: mastery, count: 1);
    expect(top.length, 1);
    expect(top.first.tag, 'a');
  });
}
