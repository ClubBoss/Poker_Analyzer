import '../models/player_profile.dart';
import '../models/theory_cluster_summary.dart';

/// Suggests a starting point into theory learning for a new player.
class TheoryOnboardingPathRecommender {
  const TheoryOnboardingPathRecommender();

  /// Chooses the best [TheoryClusterSummary] from [clusters] for [profile].
  TheoryClusterSummary? recommendEntryCluster(
    List<TheoryClusterSummary> clusters,
    PlayerProfile profile,
  ) {
    if (clusters.isEmpty) return null;
    var filtered = clusters
        .where(
          (c) =>
              c.entryPointIds.isNotEmpty &&
              c.sharedTags.any((t) => profile.tags.contains(t)),
        )
        .toList();
    if (filtered.isEmpty) {
      filtered = clusters.where((c) => c.entryPointIds.isNotEmpty).toList();
    }
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => _score(b, profile).compareTo(_score(a, profile)));
    return filtered.first;
  }

  /// Returns the lesson id of the recommended entry point.
  String? recommendEntryLesson(
    List<TheoryClusterSummary> clusters,
    PlayerProfile profile,
  ) {
    final cluster = recommendEntryCluster(clusters, profile);
    if (cluster == null) return null;
    for (final id in cluster.entryPointIds) {
      if (!profile.completedLessonIds.contains(id)) return id;
    }
    return cluster.entryPointIds.isNotEmpty
        ? cluster.entryPointIds.first
        : null;
  }

  double _score(TheoryClusterSummary c, PlayerProfile profile) {
    final match = c.sharedTags.where(profile.tags.contains).length;
    final gap = c.sharedTags.difference(profile.tags).length;
    final base = match * 2 + gap;
    return base / (c.size == 0 ? 1 : c.size);
  }
}
