import 'package:shared_preferences/shared_preferences.dart';

import '../models/pinned_learning_item.dart';

/// Logs user interactions with pinned comeback nudges and stores simple
/// counters/timestamps in [SharedPreferences].
class PinnedInteractionLoggerService {
  PinnedInteractionLoggerService._();

  /// Singleton instance.
  static final PinnedInteractionLoggerService instance =
      PinnedInteractionLoggerService._();

  static String _openKey(String id) => 'pinned_open_$id';
  static String _seenKey(String id) => 'pinned_seen_$id';
  static String _dismissKey(String id) => 'pinned_dismiss_$id';
  static String _lastOpenKey(String id) => 'pinned_open_last_$id';
  static String _lastDismissKey(String id) => 'pinned_dismiss_last_$id';

  /// Records an impression of a pinned nudge.
  Future<void> logImpression(PinnedLearningItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _seenKey(item.id);
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
  }

  /// Records that the pinned nudge was opened.
  Future<void> logOpened(PinnedLearningItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final openKey = _openKey(item.id);
    final count = (prefs.getInt(openKey) ?? 0) + 1;
    await prefs.setInt(openKey, count);
    await prefs.setInt(
      _lastOpenKey(item.id),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Records that the pinned nudge was dismissed without opening.
  Future<void> logDismissed(PinnedLearningItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dismissKey(item.id);
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
    await prefs.setInt(
      _lastDismissKey(item.id),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns how many times the pinned nudge for [id] was opened.
  Future<int> getOpenCount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_openKey(id)) ?? 0;
  }

  /// Returns the last time a pinned nudge for [id] was opened.
  Future<DateTime?> getLastOpened(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastOpenKey(id));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Returns the last time a pinned nudge for [id] was dismissed.
  Future<DateTime?> getLastDismissed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastDismissKey(id));
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Clears dismissal-related fatigue metrics for [id].
  Future<void> clearFatigueFor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissKey(id));
    await prefs.remove(_lastDismissKey(id));
  }

  /// Returns a raw stats map useful for debugging.
  Future<Map<String, dynamic>> getStatsFor(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'impressions': prefs.getInt(_seenKey(id)) ?? 0,
      'opens': prefs.getInt(_openKey(id)) ?? 0,
      'dismissals': prefs.getInt(_dismissKey(id)) ?? 0,
      'lastOpened': prefs.getInt(_lastOpenKey(id)),
      'lastDismissed': prefs.getInt(_lastDismissKey(id)),
    };
  }
}

