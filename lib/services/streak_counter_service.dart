import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'training_stats_service.dart';
import 'daily_target_service.dart';

class StreakCounterService extends ChangeNotifier {
  static const _countKey = 'target_streak_count';
  static const _lastKey = 'target_streak_last';
  static const _maxKey = 'target_streak_max';

  final TrainingStatsService stats;
  final DailyTargetService target;

  int _count = 0;
  DateTime? _last;
  int _max = 0;

  int get count => _count;
  DateTime? get lastSuccess => _last;
  int get max => _max;

  StreakCounterService({required this.stats, required this.target}) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _count = prefs.getInt(_countKey) ?? 0;
    _max = prefs.getInt(_maxKey) ?? 0;
    final lastStr = prefs.getString(_lastKey);
    _last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    await _updateForToday();
    stats.handsStream.listen((_) => _checkToday());
    target.addListener(_checkToday);
    _checkToday();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, _count);
    await prefs.setInt(_maxKey, _max);
    if (_last != null) {
      await prefs.setString(_lastKey, _last!.toIso8601String());
    } else {
      await prefs.remove(_lastKey);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _updateForToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_last != null) {
      final lastDay = DateTime(_last!.year, _last!.month, _last!.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        _count += 1;
        if (_count > _max) _max = _count;
      } else if (diff > 1) {
        _count = 0;
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> _checkToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hands = stats.handsPerDay[today] ?? 0;
    if (hands >= target.target && (_last == null || !_isSameDay(_last!, today))) {
      _last = today;
      await _save();
    }
  }

  Future<void> restart() async {
    _count = 0;
    _last = null;
    await _save();
    notifyListeners();
  }

  @override
  void dispose() {
    target.removeListener(_checkToday);
    super.dispose();
  }
}
