
import 'recap_history_tracker.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

/// Evaluates recap history and detects user fatigue to avoid overprompting.
class RecapFatigueEvaluator {
  final RecapHistoryTracker tracker;
  RecapFatigueEvaluator({RecapHistoryTracker? tracker})
    : tracker = tracker ?? RecapHistoryTracker.instance;

  static final RecapFatigueEvaluator instance = RecapFatigueEvaluator();

  static const _globalKey = 'recap_fatigue_global';
  static const _lessonPrefix = 'recap_fatigue_lesson_';

  Future<bool> _isActive(String key) async {
    final prefs = await PreferencesService.getInstance();
    final str = prefs.getString(key);
    if (str == null) return false;
    final ts = DateTime.tryParse(str);
    if (ts == null) return false;
    if (DateTime.now().isBefore(ts)) return true;
    await prefs.remove(key);
    return false;
  }

  Future<void> _set(String key, Duration duration) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(key, DateTime.now().add(duration).toIso8601String());
  }

  /// Returns true if overall recap fatigue is detected.
  Future<bool> isFatiguedGlobally() async {
    if (await _isActive(_globalKey)) return true;
    final history = await tracker.getHistory();
    final now = DateTime.now();
    final recent24 = history.where(
      (e) => now.difference(e.timestamp) < const Duration(hours: 24),
    );
    final dismisses = recent24.where((e) => e.eventType == 'dismissed').length;
    if (dismisses >= 2) {
      await _set(_globalKey, const Duration(hours: 24));
      return true;
    }
    final shown = recent24.where((e) => e.eventType == 'shown').length;
    if (shown >= 5) {
      await _set(_globalKey, const Duration(hours: 12));
      return true;
    }
    return false;
  }

  /// Returns true if [lessonId] specific fatigue is detected.
  Future<bool> isLessonFatigued(String lessonId) async {
    if (lessonId.isEmpty) return false;
    final key = '$_lessonPrefix$lessonId';
    if (await _isActive(key)) return true;
    final history = await tracker.getHistory(lessonId: lessonId);
    final now = DateTime.now();
    final recent48 = history.where(
      (e) => now.difference(e.timestamp) < const Duration(hours: 48),
    );
    final dismisses = recent48.where((e) => e.eventType == 'dismissed').length;
    if (dismisses >= 3) {
      await _set(key, const Duration(days: 3));
      return true;
    }
    return false;
  }

  /// Remaining cooldown based on active fatigue flags.
  Future<Duration> recommendedCooldown() async {
    final prefs = await PreferencesService.getInstance();
    DateTime? until;
    final globalStr = prefs.getString(_globalKey);
    if (globalStr != null) {
      final ts = DateTime.tryParse(globalStr);
      if (ts != null) until = ts;
    }
    for (final k in prefs.getKeys()) {
      if (!k.startsWith(_lessonPrefix)) continue;
      final str = prefs.getString(k);
      final ts = str != null ? DateTime.tryParse(str) : null;
      if (ts != null && (until == null || ts.isAfter(until!))) {
        until = ts;
      }
    }
    if (until == null) return Duration.zero;
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Light fatigue check based purely on recent interaction history.
  ///
  /// Returns true if recap prompts should be temporarily suppressed for
  /// [lessonId] based on the following rules:
  ///   * 3 or more dismissals of any recap in the last 24 hours
  ///   * the same lesson was shown less than 6 hours ago
  ///   * the lesson was completed at any time today
  Future<bool> isFatigued(String lessonId) async {
    final history = await tracker.getHistory();
    final now = DateTime.now();

    // Count dismissals globally in the last 24h
    final dismiss24 = history.where((e) {
      return e.eventType == 'dismissed' &&
          now.difference(e.timestamp) < const Duration(hours: 24);
    }).length;
    if (dismiss24 >= 3) return true;

    // Events filtered for the specific lesson
    final lessonEvents = history
        .where((e) => e.lessonId == lessonId)
        .toList(growable: false);

    // Last time the lesson banner was shown
    for (final e in lessonEvents) {
      if (e.eventType == 'shown') {
        if (now.difference(e.timestamp) < const Duration(hours: 6)) {
          return true;
        }
        break; // events are ordered newest first
      }
    }

    // Completion logged for the lesson today
    final today = DateTime(now.year, now.month, now.day);
    for (final e in lessonEvents) {
      if (e.eventType == 'completed' && e.timestamp.isAfter(today)) {
        return true;
      }
    }

    return false;
  }
}
