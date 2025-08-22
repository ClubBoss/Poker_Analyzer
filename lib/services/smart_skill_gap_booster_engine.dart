import 'mini_lesson_library_service.dart';
import 'skill_gap_detector_service.dart';
import 'mini_lesson_progress_tracker.dart';
import '../models/theory_mini_lesson_node.dart';

/// Generates theory mini lesson boosters targeting missing or undertrained tags.
class SmartSkillGapBoosterEngine {
  final SkillGapDetectorService detector;
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;

  SmartSkillGapBoosterEngine({
    SkillGapDetectorService? detector,
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
  }) : detector = detector ?? SkillGapDetectorService(),
       library = library ?? MiniLessonLibraryService.instance,
       progress = progress ?? MiniLessonProgressTracker.instance;

  /// Returns up to [max] mini lessons that fill skill gaps.
  Future<List<TheoryMiniLessonNode>> recommend({int max = 3}) async {
    if (max <= 0) return [];
    final tags = await detector.getMissingTags();
    if (tags.isEmpty) return [];

    final tagSet = {for (final t in tags) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);
    if (tagSet.isEmpty) return [];

    await library.loadAll();
    final lessons = library.getByTags(tagSet);
    if (lessons.isEmpty) return [];

    final scored = <_Entry>[];
    for (final l in lessons) {
      final lessonTags = {for (final t in l.tags) t.trim().toLowerCase()};
      final overlap = lessonTags.intersection(tagSet);
      if (overlap.isEmpty) continue;
      final views = await progress.viewCount(l.id);
      final score = overlap.length * 10 - views;
      scored.add(_Entry(l, score, overlap));
    }
    if (scored.isEmpty) return [];

    scored.sort((a, b) => b.score.compareTo(a.score));

    final result = <TheoryMiniLessonNode>[];
    final covered = <String>{};
    for (final e in scored) {
      if (result.length >= max) break;
      final uncovered = e.tags.difference(covered);
      if (uncovered.isEmpty) continue;
      result.add(e.lesson);
      covered.addAll(uncovered);
    }
    return result;
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final double score;
  final Set<String> tags;
  _Entry(this.lesson, this.score, this.tags);
}
