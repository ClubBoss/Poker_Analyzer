import '../models/learning_path_template_v2.dart';

/// Simple engine computing overall learning path progress.
class LearningPathProgressEngine {
  LearningPathProgressEngine();

  /// Returns how many stages from [path] are included in [completedStageIds].
  int completedStages(
    LearningPathTemplateV2 path,
    Set<String> completedStageIds,
  ) {
    var count = 0;
    for (final stage in path.stages) {
      if (completedStageIds.contains(stage.id)) count++;
    }
    return count;
  }

  /// Computes completion ratio from 0.0 to 1.0 for [path].
  double computeProgress(
    LearningPathTemplateV2 path,
    Set<String> completedStageIds,
  ) {
    if (path.stages.isEmpty) return 0.0;
    final done = completedStages(path, completedStageIds);
    return done / path.stages.length;
  }
}
