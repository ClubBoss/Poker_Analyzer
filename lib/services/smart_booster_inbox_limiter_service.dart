import 'package:shared_preferences/shared_preferences.dart';

import '../utils/shared_prefs_keys.dart';
import 'smart_booster_exclusion_tracker_service.dart';

/// Limits how often booster inbox banners can be shown per tag and per day.
class SmartBoosterInboxLimiterService {
  SmartBoosterInboxLimiterService();

  static const int maxPerDay = 2;
  static const Duration tagCooldown = Duration(hours: 48);
  static const String _totalDateKey = SharedPrefsKeys.boosterInboxTotalDate;
  static const String _totalCountKey = SharedPrefsKeys.boosterInboxTotalCount;

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
      await SmartBoosterExclusionTrackerService()
          .logExclusion(tag, 'rateLimited');
      return false;
    }

    final lastMillis = prefs.getInt(SharedPrefsKeys.boosterInboxLast(tag));
    if (lastMillis != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      if (now.difference(last) < tagCooldown) {
        await SmartBoosterExclusionTrackerService()
            .logExclusion(tag, 'rateLimited');
        return false;
      }
    }
    return true;
  }

  /// Records that a booster for [tag] was shown now.
  Future<void> recordShown(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(
      SharedPrefsKeys.boosterInboxLast(tag),
      now.millisecondsSinceEpoch,
    );

    final dateKey = _todayKey(now);
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
    final dateKey = _todayKey(DateTime.now());
    final storedDate = prefs.getString(_totalDateKey);
    if (storedDate != dateKey) return 0;
    return prefs.getInt(_totalCountKey) ?? 0;
  }
}
