import "theory_cluster_summary.dart";

/// Information linking a booster pack back to mistakes or weak clusters.
class BoosterBacklink {
  final TheoryClusterSummary? sourceCluster;
  final Set<String> matchingTags;
  final List<String> relatedLessonIds;

  const BoosterBacklink({
    this.sourceCluster,
    Set<String>? matchingTags,
    List<String>? relatedLessonIds,
  }) : matchingTags = matchingTags ?? const {},
       relatedLessonIds = relatedLessonIds ?? const [];
}
