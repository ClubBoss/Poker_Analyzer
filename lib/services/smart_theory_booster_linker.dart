import '../services/theory_cluster_summary_service.dart';
import '../services/theory_lesson_tag_clusterer.dart';

/// Generates deep links to theory clusters based on completed lessons or tags.
class SmartTheoryBoosterLinker {
  final TheoryLessonTagClusterer clusterer;
  final TheoryClusterSummaryService summaryService;

  const SmartTheoryBoosterLinker({
    TheoryLessonTagClusterer? clusterer,
    TheoryClusterSummaryService? summaryService,
  }) : clusterer = clusterer ?? TheoryLessonTagClusterer(),
       summaryService = summaryService ?? TheoryClusterSummaryService();

  /// Returns a deep link for the cluster containing [lessonId].
  Future<String?> linkForLesson(String lessonId) async {
    final clusters = await clusterer.clusterLessons();
    for (final c in clusters) {
      if (c.lessons.any((l) => l.id == lessonId)) {
        final summary = summaryService.generateSummary(c);
        if (summary.entryPointIds.isNotEmpty) {
          return '/theory/cluster?clusterId=${summary.entryPointIds.first}';
        }
      }
    }
    return null;
  }

  /// Returns a deep link to the best matching cluster for [tags].
  Future<String?> linkForTags(List<String> tags) async {
    final queryTags = {for (final t in tags) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);
    if (queryTags.isEmpty) return null;

    final clusters = await clusterer.clusterLessons();
    String? link;
    double best = 0;
    for (final c in clusters) {
      final clusterTags = {for (final t in c.tags) t.trim().toLowerCase()}
        ..removeWhere((t) => t.isEmpty);
      final overlap = clusterTags.intersection(queryTags).length.toDouble();
      if (overlap > best && clusterTags.isNotEmpty) {
        final summary = summaryService.generateSummary(c);
        if (summary.entryPointIds.isNotEmpty) {
          best = overlap;
          link = '/theory/cluster?clusterId=${summary.entryPointIds.first}';
        }
      }
    }
    return link;
  }
}
