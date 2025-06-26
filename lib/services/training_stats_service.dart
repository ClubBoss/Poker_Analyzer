import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingStatsService extends ChangeNotifier {
  static TrainingStatsService? _instance;
  static TrainingStatsService? get instance => _instance;

  TrainingStatsService() {
    _instance = this;
  }
  static const _sessionsKey = 'stats_sessions';
  static const _handsKey = 'stats_hands';
  static const _mistakesKey = 'stats_mistakes';
  static const _sessionsHistKey = 'stats_sessions_hist';
  static const _handsHistKey = 'stats_hands_hist';
  static const _mistakesHistKey = 'stats_mistakes_hist';
  static const _currentStreakKey = 'stats_current_streak';
  static const _bestStreakKey = 'stats_best_streak';

  int _sessions = 0;
  int _hands = 0;
  int _mistakes = 0;

  int _currentStreak = 0;
  int _bestStreak = 0;

  Map<String, int> _sessionsPerDay = {};
  Map<String, int> _handsPerDay = {};
  Map<String, int> _mistakesPerDay = {};

  Map<DateTime, int> get handsPerDay =>
      {for (final e in _handsPerDay.entries) DateTime.parse(e.key): e.value};

  final _sessionController = StreamController<int>.broadcast();
  final _handsController = StreamController<int>.broadcast();
  final _mistakeController = StreamController<int>.broadcast();

  int get sessionsCompleted => _sessions;
  int get handsReviewed => _hands;
  int get mistakesFixed => _mistakes;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;

  Stream<int> get sessionsStream => _sessionController.stream;
  Stream<int> get handsStream => _handsController.stream;
  Stream<int> get mistakesStream => _mistakeController.stream;

  List<MapEntry<DateTime, int>> _entries(Map<String, int> map) {
    return map.entries
        .map((e) => MapEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  List<MapEntry<DateTime, int>> handsDaily([int days = 7]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return [for (final e in _entries(_handsPerDay)) if (!e.key.isBefore(start)) e];
  }

  List<MapEntry<DateTime, int>> sessionsDaily([int days = 7]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return [for (final e in _entries(_sessionsPerDay)) if (!e.key.isBefore(start)) e];
  }

  List<MapEntry<DateTime, int>> mistakesDaily([int days = 7]) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return [for (final e in _entries(_mistakesPerDay)) if (!e.key.isBefore(start)) e];
  }

  List<MapEntry<DateTime, int>> _groupWeekly(List<MapEntry<DateTime, int>> daily) {
    final Map<DateTime, int> grouped = {};
    for (final e in daily) {
      final w = e.key.subtract(Duration(days: e.key.weekday - 1));
      grouped.update(w, (v) => v + e.value, ifAbsent: () => e.value);
    }
    final list = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  List<MapEntry<DateTime, int>> handsWeekly([int weeks = 4]) {
    final daily = handsDaily(weeks * 7);
    return _groupWeekly(daily);
  }

  List<MapEntry<DateTime, int>> sessionsWeekly([int weeks = 4]) {
    final daily = sessionsDaily(weeks * 7);
    return _groupWeekly(daily);
  }

  List<MapEntry<DateTime, int>> mistakesWeekly([int weeks = 4]) {
    final daily = mistakesDaily(weeks * 7);
    return _groupWeekly(daily);
  }

  Map<String, int> _loadMap(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return {for (final e in data.entries) e.key: e.value as int};
  }

  Future<void> _saveMap(SharedPreferences prefs, String key, Map<String, int> map) async {
    await prefs.setString(key, jsonEncode(map));
  }

  void _trim(Map<String, int> map) {
    final keys = map.keys.toList()..sort();
    while (keys.length > 30) {
      map.remove(keys.first);
      keys.removeAt(0);
    }
  }

  int _calcCurrentStreak() {
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0;; i++) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final key = day.toIso8601String().split('T').first;
      final hands = _handsPerDay[key] ?? 0;
      final mistakes = _mistakesPerDay[key] ?? 0;
      if (hands > 0 && mistakes == 0) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calcBestStreak() {
    final allKeys = {
      ..._handsPerDay.keys,
      ..._mistakesPerDay.keys,
    }..removeWhere((e) => e.isEmpty);
    final dates = allKeys.map(DateTime.parse).toList()..sort();
    int best = 0;
    int current = 0;
    DateTime? prev;
    for (final d in dates) {
      final key = d.toIso8601String().split('T').first;
      final hands = _handsPerDay[key] ?? 0;
      final mistakes = _mistakesPerDay[key] ?? 0;
      if (prev != null && d.difference(prev!).inDays > 1) current = 0;
      if (hands > 0 && mistakes == 0) {
        current += 1;
        if (current > best) best = current;
      } else {
        current = 0;
      }
      prev = d;
    }
    return best;
  }

  Future<void> _updateStreaks() async {
    _currentStreak = _calcCurrentStreak();
    _bestStreak = _calcBestStreak();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStreakKey, _currentStreak);
    await prefs.setInt(_bestStreakKey, _bestStreak);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sessions = prefs.getInt(_sessionsKey) ?? 0;
    _hands = prefs.getInt(_handsKey) ?? 0;
    _mistakes = prefs.getInt(_mistakesKey) ?? 0;
    _sessionsPerDay = _loadMap(prefs, _sessionsHistKey);
    _handsPerDay = _loadMap(prefs, _handsHistKey);
    _mistakesPerDay = _loadMap(prefs, _mistakesHistKey);
    _currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    await _updateStreaks();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionsKey, _sessions);
    await prefs.setInt(_handsKey, _hands);
    await prefs.setInt(_mistakesKey, _mistakes);
    await _saveMap(prefs, _sessionsHistKey, _sessionsPerDay);
    await _saveMap(prefs, _handsHistKey, _handsPerDay);
    await _saveMap(prefs, _mistakesHistKey, _mistakesPerDay);
    await prefs.setInt(_currentStreakKey, _currentStreak);
    await prefs.setInt(_bestStreakKey, _bestStreak);
  }

  Future<void> incrementSessions() async {
    _sessions += 1;
    final key = DateTime.now().toIso8601String().split('T').first;
    _sessionsPerDay.update(key, (v) => v + 1, ifAbsent: () => 1);
    _trim(_sessionsPerDay);
    await _save();
    notifyListeners();
    _sessionController.add(_sessions);
  }

  Future<void> incrementHands([int count = 1]) async {
    _hands += count;
    final key = DateTime.now().toIso8601String().split('T').first;
    _handsPerDay.update(key, (v) => v + count, ifAbsent: () => count);
    _trim(_handsPerDay);
    await _updateStreaks();
    await _save();
    notifyListeners();
    _handsController.add(_hands);
  }

  Future<void> incrementMistakes([int count = 1]) async {
    _mistakes += count;
    final key = DateTime.now().toIso8601String().split('T').first;
    _mistakesPerDay.update(key, (v) => v + count, ifAbsent: () => count);
    _trim(_mistakesPerDay);
    await _updateStreaks();
    await _save();
    notifyListeners();
    _mistakeController.add(_mistakes);
  }

  @override
  void dispose() {
    _sessionController.close();
    _handsController.close();
    _mistakeController.close();
    super.dispose();
  }
}
