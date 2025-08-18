import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'mini_lesson_library_service.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_prompt_dismiss_tracker.dart';

/// Re-prompts skipped theory boosters after a cooldown period.
class TheoryBoosterRecallEngine {
  final MiniLessonLibraryService library;

  TheoryBoosterRecallEngine({MiniLessonLibraryService? library})
    : library = library ?? MiniLessonLibraryService.instance;

  static final TheoryBoosterRecallEngine instance = TheoryBoosterRecallEngine();

  static const String _prefsKey = 'booster_recall_history';

  final Map<String, DateTime> _cache = <String, DateTime>{};
  bool _loaded = false;

  /// Clear cache for testing.
  void resetForTest() {
    _loaded = false;
    _cache.clear();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw);
        if (data is Map) {
          data.forEach((key, value) {
            final ts = DateTime.tryParse(value.toString());
            if (ts != null) _cache[key.toString()] = ts;
          });
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        for (final e in _cache.entries) e.key: e.value.toIso8601String(),
      }),
    );
  }

  /// Records that [lessonId] was suggested to the user.
  Future<void> recordSuggestion(String lessonId, {DateTime? timestamp}) async {
    await _load();
    _cache.putIfAbsent(lessonId, () => timestamp ?? DateTime.now());
    await _save();
  }

  /// Records that [lessonId] was launched so it won't be recalled later.
  Future<void> recordLaunch(String lessonId) async {
    await _load();
    if (_cache.remove(lessonId) != null) {
      await _save();
    }
  }

  /// Returns lessons that were suggested but never launched and are older than
  /// [after].
  Future<List<TheoryMiniLessonNode>> recallUnlaunched({
    Duration after = const Duration(days: 3),
  }) async {
    await _load();
    await library.loadAll();
    final cutoff = DateTime.now().subtract(after);
    final result = <TheoryMiniLessonNode>[];
    for (final entry in _cache.entries) {
      if (entry.value.isBefore(cutoff)) {
        final lesson = library.getById(entry.key);
        if (lesson != null) result.add(lesson);
      }
    }
    return result;
  }

  /// Returns lessons that were dismissed without launching and are older than
  /// [since].
  Future<List<TheoryMiniLessonNode>> recallDismissedUnlaunched({
    Duration since = const Duration(days: 3),
  }) async {
    await _load();
    await library.loadAll();
    final cutoff = DateTime.now().subtract(since);
    final dismisses = await TheoryPromptDismissTracker.instance.getHistory(
      before: cutoff,
    );
    final result = <TheoryMiniLessonNode>[];
    for (final d in dismisses) {
      final ts = _cache[d.lessonId];
      if (ts != null && ts.isBefore(cutoff)) {
        final lesson = library.getById(d.lessonId);
        if (lesson != null) result.add(lesson);
      }
    }
    return result;
  }
}
