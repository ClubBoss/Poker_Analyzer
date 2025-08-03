import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Queue service scheduling theory lesson reviews using spaced repetition.
class TheoryReinforcementQueueService {
  TheoryReinforcementQueueService._();
  static final TheoryReinforcementQueueService instance =
      TheoryReinforcementQueueService._();

  static const _prefsKey = 'theory_reinforcement_queue';
  static const List<Duration> _intervals = [
    Duration(days: 2),
    Duration(days: 5),
    Duration(days: 12),
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

  /// Registers a successful completion for [lessonId].
  Future<void> registerSuccess(String lessonId) async {
    final map = await _load();
    final entry = map[lessonId];
    var level = entry?.level ?? 0;
    if (level >= _intervals.length) {
      map.remove(lessonId);
    } else {
      final next = DateTime.now().add(_intervals[level]);
      map[lessonId] = _Entry(level: level + 1, next: next);
    }
    await _save(map);
  }

  /// Registers a failed completion for [lessonId]. Resets progression.
  Future<void> registerFailure(String lessonId) async {
    final map = await _load();
    map[lessonId] =
        _Entry(level: 0, next: DateTime.now().add(const Duration(days: 1)));
    await _save(map);
  }

  /// Returns due lessons sorted by [nextReviewAt].
  Future<List<TheoryMiniLessonNode>> getDueLessons({
    int max = 3,
    MiniLessonLibraryService? library,
  }) async {
    final map = await _load();
    final now = DateTime.now();
    final due = <String>[];
    for (final e in map.entries) {
      if (!e.value.next.isAfter(now)) due.add(e.key);
    }
    due.sort((a, b) => map[a]!.next.compareTo(map[b]!.next));
    final lib = library ?? MiniLessonLibraryService.instance;
    await lib.loadAll();
    final result = <TheoryMiniLessonNode>[];
    for (final id in due) {
      final node = lib.getById(id);
      if (node != null) result.add(node);
      if (result.length >= max) break;
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
