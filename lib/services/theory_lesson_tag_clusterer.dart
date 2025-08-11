import '../models/theory_lesson_cluster.dart';
import 'mini_lesson_library_service.dart';

/// Groups theory mini lessons into connected clusters using tags and links.
class TheoryLessonTagClusterer {
  final MiniLessonLibraryService library;

  TheoryLessonTagClusterer({MiniLessonLibraryService? library})
      : library = library ?? MiniLessonLibraryService.instance;

  /// Returns clusters of lessons connected by tag overlap or next links.
  Future<List<TheoryLessonCluster>> clusterLessons() async {
    await library.loadAll();
    final lessons = library.all;
    if (lessons.isEmpty) return [];

    final byId = {for (final l in lessons) l.id: l};
    final adj = <String, Set<String>>{for (final l in lessons) l.id: <String>{}};

    // Build edges based on shared tags.
    final tagIndex = <String, List<String>>{};
    for (final l in lessons) {
      for (final tag in l.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isEmpty) continue;
        tagIndex.putIfAbsent(key, () => []).add(l.id);
      }
    }
    for (final ids in tagIndex.values) {
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          adj[ids[i]]!.add(ids[j]);
          adj[ids[j]]!.add(ids[i]);
        }
      }
    }

    // Build edges based on direct path links.
    for (final l in lessons) {
      for (final next in l.nextIds) {
        if (byId.containsKey(next)) {
          adj[l.id]!.add(next);
          adj[next]!.add(l.id);
        }
      }
    }

    final visited = <String>{};
    final clusters = <TheoryLessonCluster>[];

    for (final id in byId.keys) {
      if (!visited.add(id)) continue;
      final stack = <String>[id];
      final ids = <String>[];
      final tags = <String>{};

      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        ids.add(cur);
        final node = byId[cur];
        if (node != null) {
          for (final t in node.tags) {
            final tr = t.trim();
            if (tr.isNotEmpty) tags.add(tr);
          }
          for (final n in adj[cur] ?? {}) {
            if (visited.add(n)) stack.add(n);
          }
        }
      }
      final clusterLessons = [for (final cid in ids) byId[cid]!];
      clusters.add(TheoryLessonCluster(lessons: clusterLessons, tags: tags));
    }

    clusters.sort((a, b) => b.lessons.length.compareTo(a.lessons.length));
    return clusters;
  }
}
