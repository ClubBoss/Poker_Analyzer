import 'package:flutter/foundation.dart';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_progress_tracker.dart';
import 'mistake_tag_history_service.dart';
import 'theory_booster_recommender.dart';
import 'theory_completion_event_dispatcher.dart';

class TheorySessionService extends ChangeNotifier {
  final MiniLessonProgressTracker progress;
  final TheoryBoosterRecommender recommender;

  TheorySessionService({
    MiniLessonProgressTracker? progress,
    TheoryBoosterRecommender? recommender,
  })  : progress = progress ?? MiniLessonProgressTracker.instance,
        recommender = recommender ?? const TheoryBoosterRecommender();

  Future<BoosterRecommendationResult?> onComplete(
    TheoryMiniLessonNode lesson,
  ) async {
    await progress.markCompleted(lesson.id);
    final history = await MistakeTagHistoryService.getRecentHistory(limit: 50);
    final rec = await recommender.recommend(lesson, recentMistakes: history);
    TheoryCompletionEventDispatcher.instance.dispatch(
      TheoryCompletionEvent(lessonId: lesson.id, wasSuccessful: true),
    );
    return rec;
  }
}
