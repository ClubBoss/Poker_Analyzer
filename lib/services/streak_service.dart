import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the number of consecutive days the app was opened.
///
/// The streak information is persisted using [SharedPreferences] so it
/// survives app restarts. Every time the service is loaded or explicitly
/// refreshed it compares today's date with the last stored activity date and
/// updates the counter accordingly.
class StreakService extends ChangeNotifier {
  static const _lastOpenKey = 'streak_last_open';
  static const _countKey = 'streak_count';
  static const bonusThreshold = 3;
  static const bonusMultiplier = 1.5;

  DateTime? _lastOpen;
  int _count = 0;
  bool _increased = false;

  int get count => _count;
  bool get hasBonus => _count >= bonusThreshold;
  bool get increased => _increased;

  /// Returns true if the streak increased since the last check.
  bool consumeIncreaseFlag() {
    final value = _increased;
    _increased = false;
    return value;
  }

  /// Loads the persisted streak information and refreshes it for today.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStr = prefs.getString(_lastOpenKey);
    _lastOpen = lastStr != null ? DateTime.tryParse(lastStr) : null;
    _count = prefs.getInt(_countKey) ?? 0;
    await updateStreak();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastOpen != null) {
      await prefs.setString(_lastOpenKey, _lastOpen!.toIso8601String());
    } else {
      await prefs.remove(_lastOpenKey);
    }
    await prefs.setInt(_countKey, _count);
  }

  /// Compares the saved date with today and updates the streak accordingly.
  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool increased = false;

    if (_lastOpen == null) {
      // First app launch.
      _count = 1;
      _lastOpen = today;
      increased = true;
    } else {
      final last = DateTime(_lastOpen!.year, _lastOpen!.month, _lastOpen!.day);
      final diff = today.difference(last).inDays;

      if (diff == 1) {
        _count += 1;
        _lastOpen = today;
        increased = true;
      } else if (diff != 0) {
        // More than a day has passed or clock was changed.
        _count = 1;
        _lastOpen = today;
        increased = true;
      }
    }

    _increased = increased;
    await _save();
    notifyListeners();
  }
}
