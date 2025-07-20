import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks progress of lesson steps using local storage.
///
/// Supports hierarchical structure: one lesson contains multiple steps.
/// Old single-level progress data is migrated automatically on [load].
class LessonProgressTrackerService {
  LessonProgressTrackerService._();
  static final instance = LessonProgressTrackerService._();

  static const _prefsKey = 'lesson_progress';
  static const _legacyLessonId = '__legacy__';

  /// Cached progress map of `lessonId` -> completed step ids.
  final Map<String, Set<String>> _progress = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic> && data.values.every((v) => v is bool)) {
        // Legacy flat format: {stepId: true}
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
    }
    _loaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final e in _progress.entries) e.key: e.value.toList(),
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  /// Marks [stepId] as completed within [lessonId].
  Future<void> markStepCompleted(String lessonId, String stepId) async {
    if (!_loaded) await load();
    final set = _progress.putIfAbsent(lessonId, () => <String>{});
    set.add(stepId);
    await _save();
  }

  /// Returns `true` if [stepId] is completed within [lessonId].
  Future<bool> isStepCompleted(String lessonId, String stepId) async {
    if (!_loaded) await load();
    return _progress[lessonId]?.contains(stepId) ?? false;
  }

  /// Returns all completed step ids for the given [lessonId].
  Future<List<String>> getCompletedSteps(String lessonId) async {
    if (!_loaded) await load();
    return List<String>.from(_progress[lessonId] ?? const <String>{});
  }

  // ---------------------------------------------------------------------------
  // Legacy API - kept for backward compatibility with existing code.
  // ---------------------------------------------------------------------------

  @Deprecated('Use markStepCompleted(lessonId, stepId) instead')
  Future<void> markStepCompletedFlat(String stepId) async {
    await markStepCompleted(_legacyLessonId, stepId);
  }

  @Deprecated('Use isStepCompleted(lessonId, stepId) instead')
  Future<bool> isStepCompletedFlat(String stepId) async {
    return isStepCompleted(_legacyLessonId, stepId);
  }

  @Deprecated('Use getCompletedSteps(lessonId) instead')
  Future<Map<String, bool>> getCompletedStepsFlat() async {
    if (!_loaded) await load();
    final set = _progress[_legacyLessonId] ?? const <String>{};
    return {for (final id in set) id: true};
  }
}
