import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import 'theory_recall_evaluator.dart';

/// Provides recall lesson suggestions after booster completion.
class BoosterRecallBannerEngine {
  final TheoryRecallEvaluator recall;

  BoosterRecallBannerEngine({TheoryRecallEvaluator? recall})
      : recall = recall ?? const TheoryRecallEvaluator();

  static final BoosterRecallBannerEngine instance = BoosterRecallBannerEngine();

  static const _dismissPrefix = 'booster_recall_banner_dismissed_';

  /// Returns a lesson suggestion or null if none available or dismissed.
  Future<TheoryMiniLessonNode?> getSuggestion() async {
    final lessons = await recall.recallSuggestions(limit: 1);
    if (lessons.isEmpty) return null;
    final lesson = lessons.first;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('$_dismissPrefix${lesson.id}') ?? false) {
      return null;
    }
    return lesson;
  }

  /// Marks [lessonId] dismissed so it won't be suggested again.
  Future<void> dismiss(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissPrefix$lessonId', true);
  }
}
