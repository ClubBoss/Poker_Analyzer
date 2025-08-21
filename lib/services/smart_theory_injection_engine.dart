import 'mistake_tag_history_service.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'skill_gap_detector_service.dart';
import 'booster_cooldown_scheduler.dart';
import 'learning_path_stage_library.dart';
import '../models/theory_mini_lesson_node.dart';

/// Determines when to inject short theory mini lessons based on stage progress.
class SmartTheoryInjectionEngine {
  final SkillGapDetectorService detector;
  final MiniLessonProgressTracker progress;
  final MiniLessonLibraryService library;
  final BoosterCooldownScheduler cooldown;

  const SmartTheoryInjectionEngine({
    SkillGapDetectorService? detector,
    MiniLessonProgressTracker? progress,
    MiniLessonLibraryService? library,
    BoosterCooldownScheduler? cooldown,
  })  : detector = detector ?? SkillGapDetectorService(),
        progress = progress ?? MiniLessonProgressTracker.instance,
        library = library ?? MiniLessonLibraryService.instance,
        cooldown = cooldown ?? BoosterCooldownScheduler.instance;

  /// Returns a mini lesson to inject for [stageId] or `null`.
  Future<TheoryMiniLessonNode?> getInjectionCandidate(String stageId) async {
    if (await cooldown.isCoolingDown('skill_gap')) return null;

    final stage = LearningPathStageLibrary.instance.getById(stageId);
    if (stage == null) return null;

    final stageTags = {for (final t in stage.tags) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);
    if (stageTags.isEmpty) return null;

    final gaps = await detector.getMissingTags();
    final gapSet = {for (final t in gaps) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);

    final history = await MistakeTagHistoryService.getRecentHistory(limit: 50);
    final mistakeTags = <String>{};
    for (final h in history) {
      for (final t in h.tags) {
        mistakeTags.add(t.name.toLowerCase());
      }
    }

    final relevant = stageTags.intersection(gapSet).intersection(mistakeTags);
    if (relevant.isEmpty) return null;

    await library.loadAll();

    // Filter tags that haven't been seen in any lesson yet.
    final unseen = <String>{};
    for (final tag in relevant) {
      final lessons = library.getByTags({tag});
      bool seen = false;
      for (final l in lessons) {
        if (await progress.viewCount(l.id) > 0) {
          seen = true;
          break;
        }
      }
      if (!seen) unseen.add(tag);
    }
    if (unseen.isEmpty) return null;

    final lessons = library.getByTags(unseen);
    if (lessons.isEmpty) return null;

    final entries = <_Entry>[];
    for (final l in lessons) {
      if (await progress.isCompleted(l.id)) continue;
      final views = await progress.viewCount(l.id);
      entries.add(_Entry(l, views, l.content.length));
    }
    if (entries.isEmpty) return null;

    entries.sort((a, b) {
      final v = a.views.compareTo(b.views);
      if (v != 0) return v;
      return a.length.compareTo(b.length);
    });

    return entries.first.lesson;
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final int views;
  final int length;
  _Entry(this.lesson, this.views, this.length);
}
