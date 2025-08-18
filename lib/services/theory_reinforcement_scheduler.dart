import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'theory_reinforcement_entry.dart';

/// Schedules follow-up reviews for theory lessons using spaced repetition.
class TheoryReinforcementScheduler {
  TheoryReinforcementScheduler._();
  static final TheoryReinforcementScheduler instance =
      TheoryReinforcementScheduler._();

  static const _prefsKey = 'theory_reinforcement_schedule';
  static const List<Duration> _intervals = [
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
  ];

  Future<Map<String, TheoryReinforcementEntry>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          final map = <String, TheoryReinforcementEntry>{};
          for (final e in data.entries) {
            if (e.value is Map) {
              map[e.key as String] = TheoryReinforcementEntry.fromJson(
                Map<String, dynamic>.from(e.value as Map),
              );
            }
          }
          return map;
        }
      } catch (_) {}
    }
    return <String, TheoryReinforcementEntry>{};
  }

  Future<void> _save(Map<String, TheoryReinforcementEntry> map) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {for (final e in map.entries) e.key: e.value.toJson()};
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> registerSuccess(String lessonId) async {
    final map = await _load();
    final entry = map[lessonId];
    var level = entry?.level ?? 0;
    if (level < _intervals.length - 1) level++;
    final next = DateTime.now().add(_intervals[level]);
    map[lessonId] = TheoryReinforcementEntry(level: level, next: next);
    await _save(map);
  }

  Future<void> registerFailure(String lessonId) async {
    final map = await _load();
    final entry = map[lessonId];
    var level = entry?.level ?? 0;
    if (level > 0) level--;
    final next = DateTime.now().add(_intervals[level]);
    map[lessonId] = TheoryReinforcementEntry(level: level, next: next);
    await _save(map);
  }

  Future<List<String>> getDueReviews(DateTime now) async {
    final map = await _load();
    final result = <String>[];
    for (final e in map.entries) {
      if (!e.value.next.isAfter(now)) {
        result.add(e.key);
      }
    }
    return result;
  }
}
