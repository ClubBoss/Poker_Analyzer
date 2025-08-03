import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import '../models/theory_lesson_feedback.dart';

class TheoryFeedbackStorage {
  TheoryFeedbackStorage._();

  static final TheoryFeedbackStorage instance = TheoryFeedbackStorage._();

  static const String _key = 'theory_lesson_feedback';

  Future<List<TheoryLessonFeedback>> _load() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return [
      for (final s in raw)
        if (s.isNotEmpty)
          try {
            TheoryLessonFeedback.fromJson(
                jsonDecode(s) as Map<String, dynamic>)
          } catch (_) {
            null
          }
    ].whereType<TheoryLessonFeedback>().toList();
  }

  Future<void> _save(List<TheoryLessonFeedback> list) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(
      _key,
      [for (final f in list) jsonEncode(f.toJson())],
    );
  }

  Future<void> record(String lessonId, TheoryLessonFeedbackChoice choice) async {
    final list = await _load();
    final idx = list.indexWhere((e) => e.lessonId == lessonId);
    final entry = TheoryLessonFeedback(lessonId: lessonId, choice: choice);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    while (list.length > 200) {
      list.removeAt(0);
    }
    await _save(list);
  }

  Future<TheoryLessonFeedback?> getFeedback(String lessonId) async {
    final list = await _load();
    return list.firstWhere(
      (e) => e.lessonId == lessonId,
      orElse: () => null,
    );
  }

  Future<List<TheoryLessonFeedback>> getAll() => _load();
}
