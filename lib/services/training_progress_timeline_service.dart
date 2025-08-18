import '../models/learning_event.dart';
import '../models/track_play_history.dart';

class TrainingProgressTimelineService {
  const TrainingProgressTimelineService();

  List<LearningEvent> buildTimeline({
    required List<TrackPlayHistory> history,
    required Map<String, double> currentMastery,
    Map<String, double>? previousMastery,
  }) {
    final events = <LearningEvent>[];

    for (final h in history) {
      final completedAt = h.completedAt;
      if (completedAt != null) {
        events.add(
          LearningEvent(
            date: completedAt,
            type: LearningEventType.trackCompleted,
            label: h.goalId,
            meta: {
              'goalId': h.goalId,
              if (h.accuracy != null) 'accuracy': h.accuracy,
              if (h.mistakeCount != null) 'mistakeCount': h.mistakeCount,
            },
          ),
        );
      }
    }

    final dates =
        history
            .where((h) => h.completedAt != null)
            .map(
              (h) => DateTime(
                h.completedAt!.year,
                h.completedAt!.month,
                h.completedAt!.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();
    var streak = 1;
    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        streak += 1;
      } else {
        if (streak >= 2) {
          events.add(
            LearningEvent(
              date: dates[i - 1],
              type: LearningEventType.streak,
              label: '$streak-day streak',
              meta: {'days': streak},
            ),
          );
        }
        streak = 1;
      }
    }
    if (streak >= 2 && dates.isNotEmpty) {
      events.add(
        LearningEvent(
          date: dates.last,
          type: LearningEventType.streak,
          label: '$streak-day streak',
          meta: {'days': streak},
        ),
      );
    }

    if (previousMastery != null) {
      for (final entry in currentMastery.entries) {
        final prev = previousMastery[entry.key] ?? 0.0;
        final delta = entry.value - prev;
        if (delta >= 0.05) {
          events.add(
            LearningEvent(
              date: DateTime.now(),
              type: LearningEventType.masteryUp,
              label: entry.key,
              meta: {'delta': delta},
            ),
          );
        }
      }
    }

    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }
}
