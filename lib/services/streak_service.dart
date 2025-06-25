import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Tracks the number of consecutive days the app was opened.
///
/// The streak information is persisted using [SharedPreferences] so it
/// survives app restarts. Every time the service is loaded or explicitly
/// refreshed it compares today's date with the last stored activity date and
/// updates the counter accordingly.
class StreakService extends ChangeNotifier {
  static const _lastOpenKey = 'streak_last_open';
  static const _countKey = 'streak_count';
  static const _errorKey = 'error_free_streak';
  static const _historyKey = 'streak_history';
  static const bonusThreshold = 3;
  static const bonusMultiplier = 1.5;

  DateTime? _lastOpen;
  int _count = 0;
  bool _increased = false;
  int _errorFreeStreak = 0;
  Map<String, int> _history = {};

  int get count => _count;
  bool get hasBonus => _count >= bonusThreshold;
  bool get increased => _increased;
  int get errorFreeStreak => _errorFreeStreak;
  List<MapEntry<DateTime, int>> get history {
    final list = _history.entries
        .map((e) => MapEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

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
    _errorFreeStreak = prefs.getInt(_errorKey) ?? 0;
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _history = {for (final e in data.entries) e.key: e.value as int};
    }
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
    await prefs.setInt(_errorKey, _errorFreeStreak);
    await prefs.setString(_historyKey, jsonEncode(_history));
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

    final key = today.toIso8601String().split('T').first;
    _history[key] = _count;
    final keys = _history.keys.toList()..sort();
    while (keys.length > 30) {
      _history.remove(keys.first);
      keys.removeAt(0);
    }
    _increased = increased;
    await _save();
    notifyListeners();
  }

  Future<void> updateErrorFreeStreak(bool correct) async {
    final next = correct ? _errorFreeStreak + 1 : 0;
    if (next == _errorFreeStreak) return;
    _errorFreeStreak = next;
    await _save();
    notifyListeners();
  }

  Map<String, dynamic> toMap() => {
        'lastOpen': _lastOpen?.toIso8601String(),
        'count': _count,
        'errorFreeStreak': _errorFreeStreak,
        'history': _history,
      };

  Future<void> applyMap(Map<String, dynamic> data) async {
    bool changed = false;
    final count = data['count'];
    if (count is int && count > _count) {
      _count = count;
      changed = true;
    }
    final error = data['errorFreeStreak'];
    if (error is int && error > _errorFreeStreak) {
      _errorFreeStreak = error;
      changed = true;
    }
    final last = data['lastOpen'];
    if (last is String) {
      final t = DateTime.tryParse(last);
      if (t != null && (_lastOpen == null || t.isAfter(_lastOpen!))) {
        _lastOpen = t;
        changed = true;
      }
    }
    final hist = data['history'];
    if (hist is Map) {
      for (final e in hist.entries) {
        final v = e.value is int ? e.value as int : int.tryParse('${e.value}') ?? 0;
        _history.update(e.key, (val) => v > val ? v : val, ifAbsent: () => v);
      }
      changed = true;
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }
}
