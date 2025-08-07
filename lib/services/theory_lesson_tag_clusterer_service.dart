import '../models/theory_lesson_cluster.dart';
import 'theory_lesson_tag_clusterer.dart';

/// Singleton wrapper around [TheoryLessonTagClusterer] that caches results.
class TheoryLessonTagClustererService {
  TheoryLessonTagClustererService._();
  static final TheoryLessonTagClustererService instance =
      TheoryLessonTagClustererService._();

  final TheoryLessonTagClusterer _clusterer = TheoryLessonTagClusterer();
  List<TheoryLessonCluster>? _cache;

  /// Returns clusters of theory lessons linked by shared tags and paths.
  Future<List<TheoryLessonCluster>> getClusters() async {
    _cache ??= await _clusterer.clusterLessons();
    return _cache!;
  }

  /// Clears any cached cluster data forcing a recomputation on next call.
  void clearCache() => _cache = null;
}
