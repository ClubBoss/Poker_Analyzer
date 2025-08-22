import 'training_path_progress_service.dart';
import 'tag_mastery_service.dart';

/// Aggregated stats about the learning path progress.
class LearningPathSummary {
  final int totalStages;
  final int completedStages;
  final int remainingPacks;
  final double avgMastery;

  LearningPathSummary({
    required this.totalStages,
    required this.completedStages,
    required this.remainingPacks,
    required this.avgMastery,
  });
}

/// Caches learning path summary to speed up screen load.
class LearningPathSummaryCache {
  final TrainingPathProgressService path;
  final TagMasteryService mastery;

  LearningPathSummaryCache({required this.path, required this.mastery});

  LearningPathSummary? _summary;
  Future<void>? _refreshing;

  LearningPathSummary? get summary => _summary;

  Future<void> refresh() async {
    if (_refreshing != null) {
      await _refreshing;
      return;
    }
    final future = _compute();
    _refreshing = future;
    await future;
    _refreshing = null;
  }

  Future<void> _compute() async {
    final stages = await path.getStages();
    var completedStages = 0;
    var remainingPacks = 0;
    for (final entry in stages.entries) {
      final progress = await path.getProgressInStage(entry.key);
      if (progress >= 1.0) completedStages++;
      final done = await path.getCompletedPacksInStage(entry.key);
      remainingPacks += entry.value.length - done.length;
    }
    final masteryMap = await mastery.computeMastery();
    final avg = masteryMap.isEmpty
        ? 0.0
        : masteryMap.values.reduce((a, b) => a + b) / masteryMap.length;
    _summary = LearningPathSummary(
      totalStages: stages.length,
      completedStages: completedStages,
      remainingPacks: remainingPacks,
      avgMastery: avg,
    );
  }
}
