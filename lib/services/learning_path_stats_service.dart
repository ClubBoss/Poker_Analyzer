import '../models/learning_path_template_v2.dart';
import '../models/learning_path_progress_stats.dart';
import 'training_path_progress_service_v2.dart';

/// Computes detailed progress stats for a learning path.
class LearningPathStatsService {
  final TrainingPathProgressServiceV2 progress;

  const LearningPathStatsService({required this.progress});

  /// Builds progress statistics for [path] using current user progress.
  LearningPathProgressStats computeStats(LearningPathTemplateV2 path) {
    final completed = <String>{};
    for (final stage in path.stages) {
      if (progress.getStageCompletion(stage.id)) {
        completed.add(stage.id);
      }
    }

    final sections = <SectionStats>[];
    for (final section in path.sections) {
      final total = section.stageIds.length;
      final done = section.stageIds.where(completed.contains).length;
      sections.add(SectionStats(
        id: section.id,
        title: section.title,
        completedStages: done,
        totalStages: total,
      ));
    }

    final baseUnlocked = progress.unlockedStageIds().toSet();
    final locked = <String>[];

    bool sectionReady(String stageId) {
      if (path.sections.isEmpty) return true;
      final idx = path.sections.indexWhere((s) => s.stageIds.contains(stageId));
      if (idx <= 0) return true;
      final prev = path.sections[idx - 1];
      return prev.stageIds.every(completed.contains);
    }

    for (final stage in path.stages) {
      if (completed.contains(stage.id)) continue;
      var unlocked = baseUnlocked.contains(stage.id);
      if (unlocked &&
          stage.unlockAfter.isNotEmpty &&
          !stage.unlockAfter.every(completed.contains)) {
        unlocked = false;
      }
      if (unlocked && !sectionReady(stage.id)) {
        unlocked = false;
      }
      if (!unlocked) locked.add(stage.id);
    }

    final totalStages = path.stages.length;
    final finished = completed.length;
    final percent = totalStages == 0 ? 0.0 : finished / totalStages;

    return LearningPathProgressStats(
      totalStages: totalStages,
      completedStages: finished,
      completionPercent: percent,
      sections: sections,
      lockedStageIds: locked,
    );
  }
}
