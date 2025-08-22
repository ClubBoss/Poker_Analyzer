import '../models/skill_tree.dart';
import '../models/skill_tree_track_summary.dart';
import 'skill_tree_node_progress_tracker.dart';
import 'training_stats_service.dart';

/// Builds user-facing summaries for skill tree tracks.
class SkillTreeTrackSummaryBuilder {
  final SkillTreeNodeProgressTracker progress;
  final TrainingStatsService? stats;

  SkillTreeTrackSummaryBuilder({
    SkillTreeNodeProgressTracker? progress,
    this.stats,
  }) : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  /// Generates a [SkillTreeTrackSummary] for [tree].
  Future<SkillTreeTrackSummary> build(SkillTree tree) async {
    // Ensure progress is loaded
    await progress.isCompleted('');
    final completedIds = progress.completedNodeIds.value;

    var total = 0;
    var completed = 0;
    for (final node in tree.nodes.values) {
      final opt = (node as dynamic).isOptional == true;
      if (opt) continue;
      total++;
      if (completedIds.contains(node.id)) {
        completed++;
      }
    }

    final category = tree.nodes.values.isNotEmpty
        ? tree.nodes.values.first.category
        : '';

    double? avgEvLoss;
    final svc = stats ?? TrainingStatsService.instance;
    if (svc != null) {
      final stat = svc.skillStats[category];
      if (stat != null && stat.handsPlayed > 0) {
        avgEvLoss = stat.evAvg;
      }
    }

    String line;
    if (total > 0 && completed >= total) {
      line = 'Nice! You crushed all $category drills.';
    } else {
      final pct = total > 0 ? (completed / total * 100).round() : 0;
      line = 'Great progress! $pct% complete.';
    }

    return SkillTreeTrackSummary(
      title: category,
      completedCount: completed,
      avgEvLoss: avgEvLoss,
      motivationalLine: line,
    );
  }
}
