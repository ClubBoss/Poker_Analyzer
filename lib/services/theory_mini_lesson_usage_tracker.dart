import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_usage_event.dart';

/// Tracks when users manually open theory mini-lessons.
class TheoryMiniLessonUsageTracker {
  TheoryMiniLessonUsageTracker._();
  static final TheoryMiniLessonUsageTracker instance =
      TheoryMiniLessonUsageTracker._();

  static const _prefsKey = 'theory_mini_lesson_usage_log';

  Future<List<TheoryMiniLessonUsageEvent>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefsKey);
    if (str == null) return [];
    try {
      final data = jsonDecode(str);
      if (data is List) {
        return [
          for (final e in data)
            if (e is Map)
              TheoryMiniLessonUsageEvent.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return [];
  }

  Future<void> _save(List<TheoryMiniLessonUsageEvent> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final e in list) e.toJson()]),
    );
  }

  /// Logs a manual open event for a theory mini-lesson.
  Future<void> logManualOpen(String lessonId, String source) async {
    final list = await _load();
    list.insert(
      0,
      TheoryMiniLessonUsageEvent(
        lessonId: lessonId,
        source: source,
        timestamp: DateTime.now(),
      ),
    );
    while (list.length > 200) {
      list.removeLast();
    }
    await _save(list);
  }

  /// Returns up to [limit] recent manual open events.
  Future<List<TheoryMiniLessonUsageEvent>> getRecent({int limit = 50}) async {
    final list = await _load();
    return list.take(limit).toList();
  }
}
