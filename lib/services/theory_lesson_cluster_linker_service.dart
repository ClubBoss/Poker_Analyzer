import '../models/theory_lesson_cluster.dart';
import 'mini_lesson_library_service.dart';
import 'theory_suggestion_engagement_tracker_service.dart';
import 'theory_cluster_cache_service.dart';
import 'user_action_logger.dart';

/// Links theory lessons into clusters based on shared tags, linked packs,
/// and co-suggestion history.
class TheoryLessonClusterLinkerService {
  final MiniLessonLibraryService library;
  final TheorySuggestionEngagementTrackerService tracker;
  final TheoryClusterCacheService cache;

  TheoryLessonClusterLinkerService({
    MiniLessonLibraryService? library,
    TheorySuggestionEngagementTrackerService? tracker,
    TheoryClusterCacheService? cache,
  })  : library = library ?? MiniLessonLibraryService.instance,
        tracker = tracker ?? TheorySuggestionEngagementTrackerService.instance,
        cache = cache ?? TheoryClusterCacheService.instance;

  List<TheoryLessonCluster>? _clustersCache;

  /// Returns all computed clusters, building them on first use.
  Future<List<TheoryLessonCluster>> clusters() async {
    if (_clustersCache != null) return _clustersCache!;
    final ids = await cache.getAllClusterIds();
    if (ids.isNotEmpty) {
      final cached = <TheoryLessonCluster>[];
      for (final id in ids) {
        final c = await cache.loadCluster(id);
        if (c != null) cached.add(c);
      }
      if (cached.isNotEmpty) {
        _clustersCache = cached;
        await UserActionLogger.instance.log('theory_cluster_linker.load.cache');
        return _clustersCache!;
      }
    }
    _clustersCache = await _build();
    for (final c in _clustersCache!) {
      await cache.saveCluster(c);
    }
    await UserActionLogger.instance.log('theory_cluster_linker.load.fresh');
    return _clustersCache!;
  }

  /// Returns the cluster containing [lessonId], if any.
  Future<TheoryLessonCluster?> getCluster(String lessonId) async {
    final clusters = await clusters();
    for (final c in clusters) {
      for (final l in c.lessons) {
        if (l.id == lessonId) return c;
      }
    }
    return null;
  }

  Future<List<TheoryLessonCluster>> _build() async {
    await library.loadAll();
    final lessons = library.all;
    final byId = {for (final l in lessons) l.id: l};
    final adj = <String, Set<String>>{
      for (final l in lessons) l.id: <String>{}
    };

    // Shared tags.
    final tagIndex = <String, List<String>>{};
    for (final l in lessons) {
      for (final t in l.tags) {
        final key = t.trim().toLowerCase();
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

    // Shared linked packs.
    final packIndex = <String, List<String>>{};
    for (final l in lessons) {
      for (final p in l.linkedPackIds) {
        final key = p.trim();
        if (key.isEmpty) continue;
        packIndex.putIfAbsent(key, () => []).add(l.id);
      }
    }
    for (final ids in packIndex.values) {
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          adj[ids[i]]!.add(ids[j]);
          adj[ids[j]]!.add(ids[i]);
        }
      }
    }

    // Co-suggestions from engagement history.
    final events = await tracker.eventsByAction('suggested');
    final byTime = <int, List<String>>{};
    for (final e in events) {
      final t = e.timestamp.millisecondsSinceEpoch;
      byTime.putIfAbsent(t, () => []).add(e.lessonId);
    }
    final pairCounts = <String, int>{};
    for (final ids in byTime.values) {
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = ids[i];
          final b = ids[j];
          final key = a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }
    pairCounts.forEach((key, count) {
      if (count >= 3) {
        final parts = key.split('|');
        final a = parts[0];
        final b = parts[1];
        adj[a]!.add(b);
        adj[b]!.add(a);
      }
    });

    // Connected components.
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
        if (node == null) continue;
        for (final t in node.tags) {
          final tr = t.trim();
          if (tr.isNotEmpty) tags.add(tr);
        }
        for (final n in adj[cur] ?? {}) {
          if (visited.add(n)) stack.add(n);
        }
      }
      clusters.add(TheoryLessonCluster(
        lessons: [for (final cid in ids) byId[cid]!],
        tags: tags,
      ));
    }

    clusters.sort((a, b) => b.lessons.length.compareTo(a.lessons.length));
    return clusters;
  }
}
