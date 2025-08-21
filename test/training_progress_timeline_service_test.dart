import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/track_play_history.dart';
import 'package:poker_analyzer/services/training_progress_timeline_service.dart';
import 'package:poker_analyzer/models/learning_event.dart';

void main() {
  const service = TrainingProgressTimelineService();

  test('builds track completion events', () {
    final history = [
      TrackPlayHistory(
        goalId: 'g1',
        startedAt: DateTime(2023, 1, 1),
        completedAt: DateTime(2023, 1, 1),
        accuracy: 1,
        mistakeCount: 0,
      ),
    ];

    final result = service.buildTimeline(
      history: history,
      currentMastery: const {},
    );

    expect(result.length, 1);
    expect(result.first.type, LearningEventType.trackCompleted);
  });

  test('detects streak events', () {
    final history = [
      TrackPlayHistory(
        goalId: 'a',
        startedAt: DateTime(2023, 1, 1),
        completedAt: DateTime(2023, 1, 1),
      ),
      TrackPlayHistory(
        goalId: 'b',
        startedAt: DateTime(2023, 1, 2),
        completedAt: DateTime(2023, 1, 2),
      ),
      TrackPlayHistory(
        goalId: 'c',
        startedAt: DateTime(2023, 1, 3),
        completedAt: DateTime(2023, 1, 3),
      ),
    ];

    final result = service.buildTimeline(
      history: history,
      currentMastery: const {},
    );

    final streaks = result
        .where((e) => e.type == LearningEventType.streak)
        .toList();
    expect(streaks.length, 1);
    expect(streaks.first.meta?['days'], 3);
  });

  test('detects mastery improvements', () {
    final result = service.buildTimeline(
      history: const [],
      currentMastery: const {'push': 0.6},
      previousMastery: const {'push': 0.4},
    );

    final masteryEvents = result
        .where((e) => e.type == LearningEventType.masteryUp)
        .toList();
    expect(masteryEvents.length, 1);
    expect(masteryEvents.first.label, 'push');
  });
}
