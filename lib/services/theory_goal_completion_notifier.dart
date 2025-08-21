import 'dart:async';

import '../models/theory_goal.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_goal_engine.dart';
import 'theory_lesson_progress_tracker.dart';

/// Singleton service that notifies when a theory goal reaches 100% progress.
class TheoryGoalCompletionNotifier {
  final MiniLessonProgressTracker tracker;
  final TheoryGoalEngine engine;

  TheoryGoalCompletionNotifier({
    MiniLessonProgressTracker? tracker,
    TheoryGoalEngine? engine,
  }) : tracker = tracker ?? MiniLessonProgressTracker.instance,
       engine = engine ?? TheoryGoalEngine.instance {
    _sub = this.tracker.onLessonCompleted.listen((_) => _checkGoals());
  }

  static final TheoryGoalCompletionNotifier instance =
      TheoryGoalCompletionNotifier();

  StreamSubscription<String>? _sub;
  void Function(TheoryGoal goal)? _callback;

  /// Sets the callback invoked when a goal is completed.
  void setOnGoalCompleted(void Function(TheoryGoal goal) callback) {
    _callback = callback;
  }

  Future<void> _checkGoals() async {
    final goals = await engine.getActiveGoals(autoRefresh: false);
    if (goals.isEmpty) return;
    await MiniLessonLibraryService.instance.loadAll();
    const progressTracker = TheoryLessonProgressTracker();

    for (final g in List<TheoryGoal>.from(goals)) {
      final progress = await _goalProgress(g, progressTracker);
      if (progress >= g.targetProgress) {
        await engine.markCompleted(g.tagOrCluster);
        _callback?.call(g);
      }
    }
  }

  Future<double> _goalProgress(
    TheoryGoal goal,
    TheoryLessonProgressTracker tracker,
  ) async {
    final tags = goal.tagOrCluster
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
    final lessons = MiniLessonLibraryService.instance.findByTags(tags);
    if (lessons.isEmpty) return 0.0;
    return tracker.progressForLessons(lessons);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
