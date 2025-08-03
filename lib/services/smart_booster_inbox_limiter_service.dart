import 'package:shared_preferences/shared_preferences.dart';

import '../utils/booster_logger.dart';

/// Limits how often booster inbox banners can be shown per tag and per day.
class SmartBoosterInboxLimiterService {
  SmartBoosterInboxLimiterService();

  static const int maxPerDay = 2;
  static const Duration tagCooldown = Duration(hours: 48);

  static String _tagKey(String tag) => 'booster_inbox_last_$tag';
  static const String _totalDateKey = 'booster_inbox_total_date';
  static const String _totalCountKey = 'booster_inbox_total_count';

  String _todayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Whether a booster banner for [tag] can be shown now.
  Future<bool> canShow(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final dateKey = _todayKey(now);
    final storedDate = prefs.getString(_totalDateKey);
    var count = prefs.getInt(_totalCountKey) ?? 0;
    if (storedDate != dateKey) {
      count = 0;
    }
    if (count >= maxPerDay) {
      await BoosterLogger.log('canShow($tag): daily limit reached');
      return false;
    }

    final lastMillis = prefs.getInt(_tagKey(tag));
    if (lastMillis != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      if (now.difference(last) < tagCooldown) {
        await BoosterLogger.log('canShow($tag): tag cooldown active');
        return false;
      }
    }
    await BoosterLogger.log('canShow($tag): allowed');
    return true;
  }

  /// Records that a booster for [tag] was shown now.
  Future<void> recordShown(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_tagKey(tag), now.millisecondsSinceEpoch);

    final dateKey = _todayKey(now);
    final storedDate = prefs.getString(_totalDateKey);
    var count = prefs.getInt(_totalCountKey) ?? 0;
    if (storedDate != dateKey) {
      count = 0;
      await prefs.setString(_totalDateKey, dateKey);
    }
    count++;
    await prefs.setInt(_totalCountKey, count);

    await BoosterLogger.log('recordShown($tag): total today=$count');
  }

  /// Returns total boosters shown today.
  Future<int> getTotalBoostersShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _todayKey(DateTime.now());
    final storedDate = prefs.getString(_totalDateKey);
    if (storedDate != dateKey) return 0;
    return prefs.getInt(_totalCountKey) ?? 0;
  }
}
