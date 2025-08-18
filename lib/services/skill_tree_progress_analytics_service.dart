import '../models/skill_tree.dart';
import 'skill_tree_node_progress_tracker.dart';

/// Aggregated progress statistics for a skill tree.
class SkillTreeProgressStats {
  final int totalNodes;
  final int completedNodes;
  final double completionRate;
  final Map<int, double> completionRateByLevel;

  const SkillTreeProgressStats({
    required this.totalNodes,
    required this.completedNodes,
    required this.completionRate,
    required this.completionRateByLevel,
  });
}

/// Computes progress analytics for a [SkillTree].
class SkillTreeProgressAnalyticsService {
  final SkillTreeNodeProgressTracker progress;
  SkillTreeProgressAnalyticsService({SkillTreeNodeProgressTracker? progress})
    : progress = progress ?? SkillTreeNodeProgressTracker.instance;

  /// Returns completion statistics for [tree].
  Future<SkillTreeProgressStats> getStats(SkillTree tree) async {
    // Ensure progress is loaded.
    await progress.isCompleted('');

    final completed = progress.completedNodeIds.value;
    final total = tree.nodes.length;
    var completedCount = 0;
    final levelMap = <int, List<bool>>{};

    for (final node in tree.nodes.values) {
      final done = completed.contains(node.id);
      if (done) completedCount++;
      levelMap.putIfAbsent(node.level, () => []).add(done);
    }

    final rateByLevel = <int, double>{};
    for (final e in levelMap.entries) {
      final done = e.value.where((v) => v).length;
      rateByLevel[e.key] = e.value.isEmpty ? 0.0 : done / e.value.length;
    }

    final rate = total > 0 ? completedCount / total : 0.0;

    return SkillTreeProgressStats(
      totalNodes: total,
      completedNodes: completedCount,
      completionRate: rate,
      completionRateByLevel: rateByLevel,
    );
  }
}
