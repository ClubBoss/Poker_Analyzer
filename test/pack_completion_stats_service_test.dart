import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_attempt.dart';
import 'package:poker_analyzer/services/pack_completion_stats_service.dart';

void main() {
  test('computeStats aggregates per pack using latest attempts', () {
    final attempts = [
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: DateTime(2024, 1, 1),
        accuracy: 1,
        ev: 0.5,
        icm: 0.3,
      ),
      TrainingAttempt(
        packId: 'p1',
        spotId: 's1',
        timestamp: DateTime(2024, 1, 2),
        accuracy: 0,
        ev: -0.1,
        icm: -0.2,
      ),
      TrainingAttempt(
        packId: 'p1',
        spotId: 's2',
        timestamp: DateTime(2024, 1, 2),
        accuracy: 0.5,
        ev: 0.2,
        icm: 0.1,
      ),
      TrainingAttempt(
        packId: 'p2',
        spotId: 'x',
        timestamp: DateTime(2024, 1, 3),
        accuracy: 0.7,
        ev: 0.4,
        icm: 0.2,
      ),
    ];

    const service = PackCompletionStatsService();
    final stats = service.computeStats(attempts);

    expect(stats.length, 2);
    final p1 = stats['p1']!;
    expect(p1.attempts, 2);
    expect(p1.accuracy, closeTo(0.25, 0.0001));
    expect(p1.ev, closeTo(0.05, 0.0001));
    expect(p1.icm, closeTo(-0.05, 0.0001));

    final p2 = stats['p2']!;
    expect(p2.attempts, 1);
    expect(p2.accuracy, 0.7);
    expect(p2.ev, 0.4);
    expect(p2.icm, 0.2);
  });
}
