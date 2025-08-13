import 'mini_lesson_library_service.dart';

/// Result of [TheoryLessonReachabilityValidator] run.
class TheoryLessonReachabilityResult {
  final List<String> orphanIds;
  final List<String> unreachableIds;
  final List<String> cycleIds;

  const TheoryLessonReachabilityResult({
    this.orphanIds = const [],
    this.unreachableIds = const [],
    this.cycleIds = const [],
  });
}

/// Validates reachability of mini theory lessons.
class TheoryLessonReachabilityValidator {
  final MiniLessonLibraryService library;

  const TheoryLessonReachabilityValidator({MiniLessonLibraryService? library})
      : library = library ?? MiniLessonLibraryService.instance;

  /// Analyzes the mini lesson graph and returns [TheoryLessonReachabilityResult].
  TheoryLessonReachabilityResult validate({List<String> rootIds = const []}) {
    final lessons = library.all;
    if (lessons.isEmpty) return const TheoryLessonReachabilityResult();

    final byId = {for (final n in lessons) n.id: n};
    final incoming = <String, int>{for (final n in lessons) n.id: 0};

    for (final n in lessons) {
      for (final next in n.nextIds) {
        if (byId.containsKey(next)) {
          incoming[next] = (incoming[next] ?? 0) + 1;
        }
      }
    }

    final orphans = <String>[];
    for (final n in lessons) {
      if ((incoming[n.id] ?? 0) == 0 && !rootIds.contains(n.id)) {
        orphans.add(n.id);
      }
    }

    final queue = <String>[];
    if (rootIds.isNotEmpty) {
      queue.addAll(rootIds.where((id) => byId.containsKey(id)));
    } else {
      queue.addAll([
        for (final n in lessons)
          if ((incoming[n.id] ?? 0) == 0) n.id
      ]);
    }

    final reachable = <String>{};
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (!reachable.add(id)) continue;
      final node = byId[id];
      if (node == null) continue;
      for (final next in node.nextIds) {
        if (byId.containsKey(next)) queue.add(next);
      }
    }

    final unreachable = <String>[
      for (final n in lessons)
        if (!reachable.contains(n.id)) n.id
    ];

    final color = <String, int>{};
    final cycle = <String>{};

    bool dfs(String id) {
      final state = color[id] ?? 0;
      if (state == 1) {
        cycle.add(id);
        return true;
      }
      if (state == 2) return false;
      color[id] = 1;
      final node = byId[id];
      if (node != null) {
        for (final next in node.nextIds) {
          if (byId.containsKey(next) && dfs(next)) {
            cycle.add(id);
          }
        }
      }
      color[id] = 2;
      return cycle.contains(id);
    }

    for (final id in byId.keys) {
      if (color[id] != 2) dfs(id);
    }

    return TheoryLessonReachabilityResult(
      orphanIds: orphans,
      unreachableIds: unreachable,
      cycleIds: cycle.toList(),
    );
  }
}
