import '../models/theory_mini_lesson_node.dart';
import 'training_session_launcher.dart';
import 'recap_history_tracker.dart';
import 'smart_recap_banner_controller.dart';
import 'training_session_service.dart';
import 'recap_session_tag_injector.dart';

/// Handles launching a recap drill from the suggestion banner.
class RecapToDrillLauncher {
  final TrainingSessionLauncher launcher;
  final RecapHistoryTracker history;
  final SmartRecapBannerController banner;
  final TrainingSessionService sessions;

  RecapToDrillLauncher({
    TrainingSessionLauncher? launcher,
    RecapHistoryTracker? history,
    required this.banner,
    required this.sessions,
  })  : launcher = launcher ?? const TrainingSessionLauncher(),
        history = history ?? RecapHistoryTracker.instance;

  bool get _inSession =>
      sessions.currentSession != null && !sessions.isCompleted;

  /// Launches [lesson] as a targeted drill if no session is active.
  Future<void> launch(TheoryMiniLessonNode lesson) async {
    if (_inSession) return;
    final tags = RecapSessionTagInjector.instance.getSessionTags();
    await launcher.launchForMiniLesson(lesson, sessionTags: tags);
    await history.registerDrillLaunch(lesson.id);
    await banner.dismiss(recordDismissal: false);
  }
}
