import 'package:shared_preferences/shared_preferences.dart';

/// Logs user interactions with Smart Inbox items.
///
/// Stores timestamps for events like `viewed`, `clicked`, `dismissed`,
/// keyed by item id.
class SmartInboxFeedbackLoggerService {
  SmartInboxFeedbackLoggerService._();

  /// Singleton instance.
  static final SmartInboxFeedbackLoggerService instance =
      SmartInboxFeedbackLoggerService._();

  static const _prefix = 'inbox_feedback_';

  static String _key(String itemId, String event) => '$_prefix${itemId}_$event';

  /// Records [eventType] for [itemId] with current timestamp.
  ///
  /// Optional [source] can be provided to describe origin of the inbox item.
  Future<void> logEvent(String itemId, String eventType,
      {String? source}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(itemId, eventType);
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    if (source != null) {
      await prefs.setString('$key:source', source);
    }
  }

  /// Returns a map of item id -> event -> timestamp.
  Future<Map<String, Map<String, DateTime>>> getFeedbackSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, Map<String, DateTime>>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final remainder = key.substring(_prefix.length);
      final lastUnderscore = remainder.lastIndexOf('_');
      if (lastUnderscore <= 0) continue;
      final itemId = remainder.substring(0, lastUnderscore);
      final eventType = remainder.substring(lastUnderscore + 1);
      final millis = prefs.getInt(key);
      if (millis == null) continue;
      final map = result.putIfAbsent(itemId, () => <String, DateTime>{});
      map[eventType] = DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return result;
  }
}
