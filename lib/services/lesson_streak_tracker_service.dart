import 'theory_lesson_completion_logger.dart';

/// Computes current and longest streaks of consecutive days with lesson completions.
class LessonStreakTrackerService {
  LessonStreakTrackerService._();
  static final LessonStreakTrackerService instance =
      LessonStreakTrackerService._();

  final _logger = TheoryLessonCompletionLogger();

  int? _current;
  int? _longest;

  /// Clears cached values.
  void resetCache() {
    _current = null;
    _longest = null;
  }

  /// Returns the current streak, ending today or yesterday.
  Future<int> getCurrentStreak() async {
    if (_current == null) await _compute();
    return _current!;
  }

  /// Returns the longest streak recorded.
  Future<int> getLongestStreak() async {
    if (_longest == null) await _compute();
    return _longest!;
  }

  Future<void> _compute() async {
    final entries = await _logger.getCompletions();
    final days = <DateTime>{};
    for (final e in entries) {
      final t = e.timestamp.toUtc();
      days.add(DateTime.utc(t.year, t.month, t.day));
    }

    final ordered = days.toList()..sort();
    _current = 0;
    _longest = 0;
    if (ordered.isEmpty) return;

    // Compute longest streak.
    var best = 1;
    var streak = 1;
    for (var i = 1; i < ordered.length; i++) {
      final diff = ordered[i].difference(ordered[i - 1]).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        if (streak > best) best = streak;
        streak = 1;
      }
    }
    if (streak > best) best = streak;
    _longest = best;

    // Compute current streak.
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final last = ordered.last;
    if (today.difference(last).inDays > 1) {
      _current = 0;
      return;
    }
    streak = 1;
    for (var i = ordered.length - 2; i >= 0; i--) {
      final diff = ordered[i + 1].difference(ordered[i]).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        break;
      }
    }
    _current = streak;
  }
}
