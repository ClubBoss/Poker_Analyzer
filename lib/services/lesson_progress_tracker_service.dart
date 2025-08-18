import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'lesson_streak_engine.dart';
import 'lesson_goal_engine.dart';
import 'xp_reward_engine.dart';

/// Tracks progress of lesson steps and completed lessons using local storage.
///
/// Supports hierarchical structure: one lesson contains multiple steps. Old
/// single-level progress data is migrated automatically on [load].
class LessonProgressTrackerService {
  LessonProgressTrackerService._();
  static final instance = LessonProgressTrackerService._();

  static const _legacyPrefsKey = 'lesson_progress';
  static const _legacyLessonId = '__legacy__';
  static const _lessonsKey = 'completed_lessons';
  static const _stepsPrefix = 'completed_steps:';

  /// Cached progress map of `lessonId` -> completed step ids.
  final Map<String, Set<String>> _progress = {};
  final Set<String> _completedLessons = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    // Load new structured data.
    final lessons = prefs.getStringList(_lessonsKey);
    if (lessons != null) _completedLessons.addAll(lessons);

    for (final k in prefs.getKeys()) {
      if (k.startsWith(_stepsPrefix)) {
        final lessonId = k.substring(_stepsPrefix.length);
        final steps = prefs.getStringList(k) ?? <String>[];
        _progress[lessonId] = steps.toSet();
      }
    }

    // Migrate legacy flat map if present.
    final raw = prefs.getString(_legacyPrefsKey);
    if (raw != null) {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic> && data.values.every((v) => v is bool)) {
        final steps = <String>{};
        for (final e in data.entries) {
          if (e.value == true) steps.add(e.key);
        }
        if (steps.isNotEmpty) _progress[_legacyLessonId] = steps;
      } else if (data is Map<String, dynamic>) {
        for (final e in data.entries) {
          final list =
              (e.value as List?)?.map((v) => v.toString()).toList() ?? [];
          _progress[e.key] = list.toSet();
        }
      }
      await prefs.remove(_legacyPrefsKey);
    }

    _loaded = true;
  }

  Future<void> _saveLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _stepsPrefix + lessonId,
      _progress[lessonId]?.toList() ?? <String>[],
    );
  }

  Future<void> _saveLessons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lessonsKey, _completedLessons.toList());
  }

  /// Marks [stepId] as completed within [lessonId]. Also marks the lesson as
  /// completed if all steps are done (currently triggers immediately as step
  /// lists are not defined yet).
  Future<void> markStepCompleted(String lessonId, String stepId) async {
    if (!_loaded) await load();
    final set = _progress.putIfAbsent(lessonId, () => <String>{});
    if (set.add(stepId)) {
      await _saveLesson(lessonId);
      unawaited(XPRewardEngine.instance.addXp(10));
      unawaited(LessonGoalEngine.instance.updateProgress());
    }
    // Automatically mark the lesson as completed.
    await markLessonCompleted(lessonId);
    await LessonStreakEngine.instance.markTodayCompleted();
  }

  /// Marks the entire [lessonId] as completed.
  Future<void> markLessonCompleted(String lessonId) async {
    if (!_loaded) await load();
    if (_completedLessons.add(lessonId)) {
      await _saveLessons();
    }
  }

  /// IDs of all completed lessons.
  Future<Set<String>> getCompletedLessons() async {
    if (!_loaded) await load();
    return Set<String>.from(_completedLessons);
  }

  /// Returns all completed step ids for the given [lessonId].
  Future<Set<String>> getCompletedSteps(String lessonId) async {
    if (!_loaded) await load();
    return Set<String>.from(_progress[lessonId] ?? const <String>{});
  }

  /// Clears all lesson progress from storage. Used for development/testing only.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k == _lessonsKey || k.startsWith(_stepsPrefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    _progress.clear();
    _completedLessons.clear();
    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // Legacy API - kept for backward compatibility with existing code.
  // ---------------------------------------------------------------------------

  @Deprecated('Use markStepCompleted(lessonId, stepId) instead')
  Future<void> markStepCompletedFlat(String stepId) async {
    await markStepCompleted(_legacyLessonId, stepId);
  }

  @Deprecated('Use getCompletedSteps(lessonId) instead')
  Future<Map<String, bool>> getCompletedStepsFlat() async {
    if (!_loaded) await load();
    final set = _progress[_legacyLessonId] ?? const <String>{};
    return {for (final id in set) id: true};
  }

  @Deprecated('Use getCompletedLessons() instead')
  Future<bool> isStepCompletedFlat(String stepId) async {
    if (!_loaded) await load();
    return _progress[_legacyLessonId]?.contains(stepId) ?? false;
  }
}
