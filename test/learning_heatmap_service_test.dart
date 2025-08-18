import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/track_play_history.dart';
import 'package:poker_analyzer/services/learning_heatmap_service.dart';

void main() {
  const service = LearningHeatmapService();

  test('aggregates completed tracks per tag and day', () {
    final history = [
      TrackPlayHistory(
        goalId: 'push',
        startedAt: DateTime(2023, 1, 1),
        completedAt: DateTime(2023, 1, 1, 10),
      ),
      TrackPlayHistory(
        goalId: 'push',
        startedAt: DateTime(2023, 1, 1, 12),
        completedAt: DateTime(2023, 1, 1, 15),
      ),
      TrackPlayHistory(
        goalId: 'fold',
        startedAt: DateTime(2023, 1, 2),
        completedAt: DateTime(2023, 1, 2),
      ),
      TrackPlayHistory(
        goalId: 'push',
        startedAt: DateTime(2023, 1, 2),
        completedAt: DateTime(2023, 1, 2),
      ),
      TrackPlayHistory(goalId: 'push', startedAt: DateTime(2023, 1, 3)),
    ];

    final result = service.buildHeatmap(history);

    expect(result.keys.length, 2);
    final push = result['push']!;
    expect(push.length, 2);
    expect(push[0].date, DateTime(2023, 1, 1));
    expect(push[0].count, 2);
    expect(push[1].date, DateTime(2023, 1, 2));
    expect(push[1].count, 1);

    final fold = result['fold']!;
    expect(fold.length, 1);
    expect(fold.first.count, 1);
  });
}
