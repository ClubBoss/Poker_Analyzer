import '../models/theory_lesson_cluster.dart';
import '../models/theory_mini_lesson_node.dart';

/// Provides forward and backward navigation helpers within a cluster of theory
/// lessons.
class TheoryLessonNavigatorService {
  final TheoryLessonCluster cluster;

  final Map<String, TheoryMiniLessonNode> _byId = {};

  TheoryLessonNavigatorService(this.cluster) {
    for (final l in cluster.lessons) {
      _byId[l.id] = l;
    }
  }

  /// Returns the first reachable next lesson from [id] or null when none.
  TheoryMiniLessonNode? getNext(String id) {
    final node = _byId[id];
    if (node == null) return null;
    for (final next in node.nextIds) {
      final candidate = _byId[next];
      if (candidate != null) return candidate;
    }
    return null;
  }

  /// Returns the previous lesson linking to [id] or null when none.
  TheoryMiniLessonNode? getPrevious(String id) {
    for (final l in cluster.lessons) {
      if (l.nextIds.contains(id)) return _byId[l.id];
    }
    return null;
  }

  /// Returns all reachable next lesson ids from [id] limited to this cluster.
  List<String> getAllNextIds(String id) {
    final node = _byId[id];
    if (node == null) return [];
    return [
      for (final n in node.nextIds)
        if (_byId.containsKey(n)) n
    ];
  }

  /// Returns all lessons that link to [id] within this cluster.
  List<String> getAllPreviousIds(String id) {
    final result = <String>[];
    for (final l in cluster.lessons) {
      if (l.nextIds.contains(id)) result.add(l.id);
    }
    return result;
  }
}
