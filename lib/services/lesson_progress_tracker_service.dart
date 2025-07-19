import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LessonProgressTrackerService {
  LessonProgressTrackerService._();
  static final instance = LessonProgressTrackerService._();

  static const _prefsKey = 'lesson_progress';
  Map<String, bool> _progress = {};
  bool _loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _progress = {
        for (final e in data.entries) e.key: e.value == true,
      };
    } else {
      _progress = {};
    }
    _loaded = true;
  }

  Future<void> markStepCompleted(String stepId) async {
    if (!_loaded) await load();
    _progress[stepId] = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_progress));
  }

  Future<bool> isStepCompleted(String stepId) async {
    if (!_loaded) await load();
    return _progress[stepId] ?? false;
  }

  Future<Map<String, bool>> getCompletedSteps() async {
    if (!_loaded) await load();
    return Map<String, bool>.from(_progress);
  }
}
