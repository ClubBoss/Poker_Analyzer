import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyLearningGoalService extends ChangeNotifier {
  static const _prefKey = 'daily_learning_goal_completed_at';

  Timer? _timer;
  DateTime? _lastCompleted;

  DailyLearningGoalService();

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefKey);
    _lastCompleted = str != null ? DateTime.tryParse(str) : null;
    _schedule();
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () {
      notifyListeners();
      _schedule();
    });
  }

  Future<void> markCompleted() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, now.toIso8601String());
    _lastCompleted = now;
    notifyListeners();
  }

  bool get completedToday {
    final last = _lastCompleted;
    if (last == null) return false;
    return _sameDay(last, DateTime.now());
  }

  Future<bool> isGoalCompleted(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefKey);
    final last = str != null ? DateTime.tryParse(str) : null;
    if (last == null) return false;
    return _sameDay(last, date);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
