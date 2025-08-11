import 'package:shared_preferences/shared_preferences.dart';

/// Logs user interactions with decay driven booster inbox items.
///
/// Stores timestamps for [logOpened], [logDismissed] and [logCompleted]
/// events keyed by booster tag.
class DecayBoosterInteractionLoggerService {
  DecayBoosterInteractionLoggerService._();

  /// Singleton instance.
  static final DecayBoosterInteractionLoggerService instance =
      DecayBoosterInteractionLoggerService._();

  static const _prefix = 'decay_booster';

  static String _openedKey(String tag) => '$_prefix_opened_$tag';
  static String _dismissedKey(String tag) => '$_prefix_dismissed_$tag';
  static String _completedKey(String tag) => '$_prefix_completed_$tag';

  /// Records that a decay booster with [tag] was opened.
  Future<void> logOpened(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _openedKey(tag),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Records that a decay booster with [tag] was dismissed.
  Future<void> logDismissed(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _dismissedKey(tag),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Records that a decay booster with [tag] was completed.
  Future<void> logCompleted(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _completedKey(tag),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns the last time a decay booster with [tag] was opened.
  Future<DateTime?> getOpenedAt(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_openedKey(tag));
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Returns the last time a decay booster with [tag] was dismissed.
  Future<DateTime?> getDismissedAt(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_dismissedKey(tag));
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Returns the last time a decay booster with [tag] was completed.
  Future<DateTime?> getCompletedAt(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_completedKey(tag));
    return millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Returns a summary map of event type to timestamp for [tag].
  Future<Map<String, DateTime?>> getStatsFor(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? read(String key) {
      final millis = prefs.getInt(key);
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    }

    return {
      'opened': read(_openedKey(tag)),
      'dismissed': read(_dismissedKey(tag)),
      'completed': read(_completedKey(tag)),
    };
  }

  /// Returns a map of tag -> event -> timestamp for all logged boosters.
  Future<Map<String, Map<String, DateTime>>> getInteractionSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, Map<String, DateTime>>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('$_prefix_')) continue;
      final remainder = key.substring('$_prefix_'.length);
      final idx = remainder.indexOf('_');
      if (idx <= 0) continue;
      final event = remainder.substring(0, idx);
      final tag = remainder.substring(idx + 1);
      final millis = prefs.getInt(key);
      if (millis == null) continue;
      final map = result.putIfAbsent(tag, () => <String, DateTime>{});
      map[event] = DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return result;
  }
}

