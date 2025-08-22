import '../models/xp_guided_goal.dart';
import 'mini_lesson_library_service.dart';
import 'training_session_launcher.dart';

/// Dispatches XP goals to the appropriate training flow.
class GoalToTrainingLauncher {
  final MiniLessonLibraryService library;
  final TrainingSessionLauncher launcher;

  GoalToTrainingLauncher({
    this.library = MiniLessonLibraryService.instance,
    this.launcher = const TrainingSessionLauncher(),
  });

  /// Resolves the lesson for [goal] and launches it as a mini lesson.
  Future<void> launchFromGoal(XPGuidedGoal goal) async {
    await library.loadAll();
    final lesson = library.getById(goal.id);
    if (lesson == null) return;
    goal.onComplete();
    await launcher.launchForMiniLesson(lesson);
  }
}
