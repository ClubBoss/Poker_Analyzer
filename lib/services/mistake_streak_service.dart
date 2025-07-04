import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MistakeStreakService extends ChangeNotifier {
  static const _lastKey = 'mistake_streak_last';
  static const _countKey = 'mistake_streak_count';
  static const _historyKey = 'mistake_streak_history';

  DateTime? _last;
  int _count = 0;
  Map<String, int> _history = {};

  int get count => _count;
  List<MapEntry<DateTime, int>> get history {
    final list = _history.entries
        .map((e) => MapEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastKey);
    _last = str != null ? DateTime.tryParse(str) : null;
    _count = prefs.getInt(_countKey) ?? 0;
    final raw = prefs.getString(_historyKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _history = {for (final e in data.entries) e.key: e.value as int};
    }
    _update(0);
  }

  Future<void> update(int reviewCount) async {
    await _update(reviewCount);
  }

  Future<void> _update(int reviewCount) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_last == null) {
      _count = reviewCount > 0 ? 1 : 0;
    } else {
      final lastDay = DateTime(_last!.year, _last!.month, _last!.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        _count = reviewCount > 0 ? _count + 1 : 0;
      } else if (diff > 1) {
        _count = reviewCount > 0 ? 1 : 0;
      }
    }
    _last = today;
    final key = today.toIso8601String().split('T').first;
    _history[key] = _count;
    final keys = _history.keys.toList()..sort();
    while (keys.length > 30) {
      _history.remove(keys.first);
      keys.removeAt(0);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, _last!.toIso8601String());
    await prefs.setInt(_countKey, _count);
    await prefs.setString(_historyKey, jsonEncode(_history));
    notifyListeners();
  }
}
