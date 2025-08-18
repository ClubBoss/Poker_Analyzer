import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'theory_reinforcement_entry.dart';

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

  /// Registers a successful completion for [lessonId].
  Future<void> registerSuccess(String lessonId) async {
    final map = await _load();
    final entry = map[lessonId];
    final level = entry?.level ?? 0;
    if (level >= _intervals.length) {
      map.remove(lessonId);
    } else {
      final next = DateTime.now().add(_intervals[level]);
      map[lessonId] = TheoryReinforcementEntry(level: level + 1, next: next);
    }
    await _save(map);
  }

  /// Registers a failed completion for [lessonId]. Resets progression.
  Future<void> registerFailure(String lessonId) async {
    final map = await _load();
    map[lessonId] = TheoryReinforcementEntry(
      level: 0,
      next: DateTime.now().add(const Duration(days: 1)),
    );
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
