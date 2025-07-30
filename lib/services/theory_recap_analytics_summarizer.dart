import '../models/recap_analytics_summary.dart';
import '../models/theory_recap_prompt_event.dart';
import 'theory_recap_trigger_logger.dart';

/// Aggregates recap prompt logs and produces performance metrics.
class TheoryRecapAnalyticsSummarizer {
  final Future<List<TheoryRecapPromptEvent>> Function({int limit}) _loader;
  final Duration cacheDuration;

  RecapAnalyticsSummary? _cache;
  DateTime? _cacheTime;

  TheoryRecapAnalyticsSummarizer({
    Future<List<TheoryRecapPromptEvent>> Function({int limit})? loader,
    this.cacheDuration = const Duration(minutes: 10),
  }) : _loader = loader ?? TheoryRecapTriggerLogger.getRecentEvents;

  /// Returns summary statistics for recent recap events.
  Future<RecapAnalyticsSummary> summarize({int limit = 50}) async {
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < cacheDuration) {
      return _cache!;
    }

    final events = await _loader(limit: limit);

    final totalByTrigger = <String, int>{};
    final acceptedByTrigger = <String, int>{};
    final dismissedByLesson = <String, int>{};

    int streak = 0;
    for (final e in events) {
      totalByTrigger.update(e.trigger, (v) => v + 1, ifAbsent: () => 1);
      if (e.outcome == 'accepted') {
        acceptedByTrigger.update(e.trigger, (v) => v + 1, ifAbsent: () => 1);
        if (streak == 0) {
          // no-op, break not needed
        }
      } else {
        dismissedByLesson.update(e.lessonId, (v) => v + 1, ifAbsent: () => 1);
      }
      if (streak >= 0) {
        if (e.outcome == 'accepted') {
          break;
        } else {
          streak++;
        }
      }
    }

    final rates = <String, double>{};
    totalByTrigger.forEach((trigger, total) {
      final acc = acceptedByTrigger[trigger] ?? 0;
      rates[trigger] = total == 0 ? 0 : acc * 100 / total;
    });

    final mostDismissed = dismissedByLesson.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final summary = RecapAnalyticsSummary(
      acceptanceRatesByTrigger: rates,
      mostDismissedLessonIds: [for (final e in mostDismissed) e.key],
      ignoredStreakCount: streak,
    );

    _cache = summary;
    _cacheTime = DateTime.now();
    return summary;
  }
}
