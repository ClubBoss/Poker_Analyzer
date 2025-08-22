import 'mini_lesson_progress_tracker.dart';

/// Schedules mini lessons using view statistics to avoid repetition.
class MiniLessonScheduler {
  final MiniLessonProgressTracker tracker;

  MiniLessonScheduler({MiniLessonProgressTracker? tracker})
    : tracker = tracker ?? MiniLessonProgressTracker.instance;

  /// Returns [max] lesson ids from [candidates] prioritized by usage data.
  /// Lessons that appear in [excludeIds] or are already completed are skipped.
  Future<List<String>> schedule(
    List<String> candidates, {
    int max = 2,
    List<String> excludeIds = const [],
  }) async {
    if (max <= 0 || candidates.isEmpty) return [];

    final remaining = <String>[];
    for (final id in candidates) {
      if (excludeIds.contains(id)) continue;
      if (await tracker.isCompleted(id)) continue;
      remaining.add(id);
    }
    if (remaining.isEmpty) return [];

    final result = <String>[];
    while (result.length < max && remaining.isNotEmpty) {
      final least = await tracker.getLeastViewed(remaining);
      if (least == null) break;

      final count = await tracker.viewCount(least);
      final ties = <_Entry>[];
      for (final id in List<String>.from(remaining)) {
        final c = await tracker.viewCount(id);
        if (c == count) {
          final last = await tracker.lastViewed(id);
          ties.add(_Entry(id, c, last));
        }
      }

      ties.sort((a, b) {
        final at = a.lastViewed ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastViewed ?? DateTime.fromMillisecondsSinceEpoch(0);
        return at.compareTo(bt);
      });

      final chosen = ties.first.id;
      result.add(chosen);
      remaining.remove(chosen);
    }

    return result;
  }
}

class _Entry {
  final String id;
  final int viewCount;
  final DateTime? lastViewed;
  _Entry(this.id, this.viewCount, this.lastViewed);
}
