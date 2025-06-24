import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService extends ChangeNotifier {
  static const _lastOpenKey = 'streak_last_open';
  static const _countKey = 'streak_count';
  static const bonusThreshold = 3;
  static const bonusMultiplier = 1.5;

  DateTime? _lastOpen;
  int _count = 0;

  int get count => _count;
  bool get hasBonus => _count >= bonusThreshold;

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

  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_lastOpen == null) {
      _lastOpen = today;
      _count = 1;
    } else {
      final last = DateTime(_lastOpen!.year, _lastOpen!.month, _lastOpen!.day);
      final diff = today.difference(last).inDays;
      if (diff == 0) {
        // same day, no change
      } else if (diff == 1) {
        _count += 1;
        _lastOpen = today;
      } else if (diff > 1) {
        _count = 1;
        _lastOpen = today;
      }
    }
    await _save();
    notifyListeners();
  }
}
