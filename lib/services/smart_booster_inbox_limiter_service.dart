import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_key_formatter.dart';

/// Limits how often booster inbox banners can be shown per tag and per day.
class SmartBoosterInboxLimiterService {
  SmartBoosterInboxLimiterService();

  static const int maxPerDay = 2;
  static const Duration tagCooldown = Duration(hours: 48);

  static String _tagKey(String tag) => 'booster_inbox_last_$tag';
  static const String _totalDateKey = 'booster_inbox_total_date';
  static const String _totalCountKey = 'booster_inbox_total_count';

  /// Whether a booster banner for [tag] can be shown now.
  Future<bool> canShow(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final dateKey = DateKeyFormatter.format(now);
    final storedDate = prefs.getString(_totalDateKey);
    var count = prefs.getInt(_totalCountKey) ?? 0;
    if (storedDate != dateKey) {
      count = 0;
    }
    if (count >= maxPerDay) return false;

    final lastMillis = prefs.getInt(_tagKey(tag));
    if (lastMillis != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      if (now.difference(last) < tagCooldown) {
        return false;
      }
    }
    return true;
  }

  /// Records that a booster for [tag] was shown now.
  Future<void> recordShown(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_tagKey(tag), now.millisecondsSinceEpoch);

    final dateKey = DateKeyFormatter.format(now);
    final storedDate = prefs.getString(_totalDateKey);
    var count = prefs.getInt(_totalCountKey) ?? 0;
    if (storedDate != dateKey) {
      count = 0;
      await prefs.setString(_totalDateKey, dateKey);
    }
    count++;
    await prefs.setInt(_totalCountKey, count);
  }

  /// Returns total boosters shown today.
  Future<int> getTotalBoostersShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateKeyFormatter.format(DateTime.now());
    final storedDate = prefs.getString(_totalDateKey);
    if (storedDate != dateKey) return 0;
    return prefs.getInt(_totalCountKey) ?? 0;
  }
}
