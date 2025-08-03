import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


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

  Future<Map<String, _Entry>> _load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          final map = <String, _Entry>{};
          for (final e in data.entries) {
            if (e.value is Map) {
              map[e.key as String] =
                  _Entry.fromJson(Map<String, dynamic>.from(e.value as Map));
            }
          }
          return map;
        }
      } catch (_) {}
    }
    return <String, _Entry>{};
  }

  Future<void> _save(Map<String, _Entry> map) async {
    final prefs = await PreferencesService.getInstance();
    final data = {for (final e in map.entries) e.key: e.value.toJson()};
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> registerSuccess(String lessonId) async {
    final map = await _load();
    final entry = map[lessonId];
    var level = entry?.level ?? 0;
    if (level < _intervals.length - 1) level++;
    final next = DateTime.now().add(_intervals[level]);
    map[lessonId] = _Entry(level: level, next: next);
    await _save(map);
  }

  Future<void> registerFailure(String lessonId) async {
    final map = await _load();
    final entry = map[lessonId];
    var level = entry?.level ?? 0;
    if (level > 0) level--;
    final next = DateTime.now().add(_intervals[level]);
    map[lessonId] = _Entry(level: level, next: next);
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

class _Entry {
  final int level;
  final DateTime next;

  const _Entry({required this.level, required this.next});

  Map<String, dynamic> toJson() => {
        'level': level,
        'next': next.toIso8601String(),
      };

  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
        level: j['level'] is int
            ? j['level'] as int
            : int.tryParse(j['level']?.toString() ?? '') ?? 0,
        next: DateTime.tryParse(j['next']?.toString() ?? '') ?? DateTime.now(),
      );
}
