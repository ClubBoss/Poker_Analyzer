import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_lesson_trail_tracker.dart';
import 'theory_lesson_tag_clusterer.dart';
import '../models/theory_mini_lesson_node.dart';

/// Determines the best theory mini lesson to resume.
class TheoryLessonResumeEngine {
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;
  final TheoryLessonTrailTracker trail;
  final TheoryLessonTagClusterer clusterer;

  TheoryLessonResumeEngine({
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
    TheoryLessonTrailTracker? trail,
    TheoryLessonTagClusterer? clusterer,
  })  : library = library ?? MiniLessonLibraryService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance,
        trail = trail ?? TheoryLessonTrailTracker.instance,
        clusterer = clusterer ?? TheoryLessonTagClusterer();

  static final TheoryLessonResumeEngine instance = TheoryLessonResumeEngine();

  /// Returns the most relevant incomplete lesson to resume.
  Future<TheoryMiniLessonNode?> getResumeTarget() async {
    await library.loadAll();
    final recentIds = trail.getTrail(limit: 10);
    for (final id in recentIds) {
      if (!await progress.isCompleted(id)) {
        final lesson = library.getById(id);
        if (lesson != null) return lesson;
      }
    }

    if (recentIds.isNotEmpty) {
      final lastId = recentIds.first;
      final clusters = await clusterer.clusterLessons();
      for (final c in clusters) {
        if (c.lessons.any((l) => l.id == lastId)) {
          for (final l in c.lessons) {
            if (!await progress.isCompleted(l.id)) return l;
          }
          break;
        }
      }
    }

    for (final l in library.all) {
      if (!await progress.isCompleted(l.id)) return l;
    }
    return null;
  }
}
