import '../models/skill_tree_node_model.dart';
import '../services/decay_tag_retention_tracker_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/booster_library_service.dart';

/// Union type for items that can be inserted into a learning path.
typedef LearningPathEntry = Object;

/// Injects decay-based review items before unlocking a skill node.
class SkillNodeDecayReviewInjector {
  final DecayTagRetentionTrackerService retention;
  final MiniLessonLibraryService lessons;
  final BoosterLibraryService boosters;

  SkillNodeDecayReviewInjector({
    DecayTagRetentionTrackerService? retention,
    MiniLessonLibraryService? lessons,
    BoosterLibraryService? boosters,
  })  : retention = retention ?? const DecayTagRetentionTrackerService(),
        lessons = lessons ?? MiniLessonLibraryService.instance,
        boosters = boosters ?? BoosterLibraryService.instance;

  /// Returns review entries for decayed tags tied to [node].
  ///
  /// Reviews are suggested before the node is unlocked so learners can
  /// refresh forgotten concepts.
  Future<List<LearningPathEntry>> injectDecayReviews(
    SkillTreeNodeModel node, {
    double thresholdDays = 30,
  }) async {
    final tags = <String>{};

    await lessons.loadAll();
    final lesson = lessons.getById(node.theoryLessonId);
    if (lesson != null) {
      tags.addAll(lesson.tags.map((t) => t.trim().toLowerCase()));
    }

    await boosters.loadAll();
    final pack = boosters.getById(node.trainingPackId);
    if (pack != null) {
      tags.addAll(pack.tags.map((t) => t.trim().toLowerCase()));
      final metaTag = pack.meta['tag']?.toString();
      if (metaTag != null && metaTag.isNotEmpty) {
        tags.add(metaTag.trim().toLowerCase());
      }
    }

    if (tags.isEmpty) return [];

    final entries = <LearningPathEntry>[];
    for (final tag in tags) {
      final days = await retention.getDecayScore(tag);
      if (days <= thresholdDays) continue;

      final lessonMatches = lessons.findByTags([tag]);
      if (lessonMatches.isNotEmpty) {
        entries.add(lessonMatches.first);
        continue;
      }

      final boosterPacks = boosters.findByTag(tag);
      if (boosterPacks.isNotEmpty) {
        final firstPack = boosterPacks.first;
        if (firstPack.spots.isNotEmpty) {
          entries.add(firstPack.spots.first);
        }
      }
    }

    return entries;
  }
}

