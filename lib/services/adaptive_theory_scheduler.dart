import 'dart:math';

import '../models/player_profile.dart';
import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'tag_mastery_service.dart';

/// Service recommending the optimal next theory lesson.
class AdaptiveTheoryScheduler {
  final MiniLessonLibraryService library;
  final TagMasteryService mastery;

  AdaptiveTheoryScheduler({
    MiniLessonLibraryService? library,
    required this.mastery,
  }) : library = library ?? MiniLessonLibraryService.instance;

  /// Returns the best next lesson for [profile] or null if none available.
  Future<TheoryMiniLessonNode?> recommendNextLesson(
    PlayerProfile profile,
  ) async {
    await library.loadAll();
    final lessons = library.all;
    if (lessons.isEmpty) return null;

    final byId = {for (final l in lessons) l.id: l};

    // Build incoming edge map to check prerequisites.
    final incoming = <String, Set<String>>{
      for (final l in lessons) l.id: <String>{},
    };
    for (final l in lessons) {
      for (final next in l.nextIds) {
        if (incoming.containsKey(next)) incoming[next]!.add(l.id);
      }
    }

    // Determine reachable ids following paths from completed lessons or roots.
    final roots = <String>{};
    for (final l in lessons) {
      if (incoming[l.id]!.isEmpty) roots.add(l.id);
    }
    final queue = <String>[
      if (profile.completedLessonIds.isEmpty)
        ...roots
      else
        ...profile.completedLessonIds,
    ];
    final reachable = <String>{};
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      final node = byId[id];
      if (node == null) continue;
      for (final next in node.nextIds) {
        if (reachable.add(next)) queue.add(next);
      }
    }

    // Compute unlocked candidate lessons.
    final candidates = <TheoryMiniLessonNode>[];
    for (final id in reachable) {
      final node = byId[id];
      if (node == null) continue;
      if (profile.completedLessonIds.contains(id)) continue;
      final prereq = incoming[id]!;
      if (prereq.isNotEmpty &&
          !prereq.every(profile.completedLessonIds.contains)) {
        continue;
      }
      candidates.add(node);
    }
    if (candidates.isEmpty) return null;

    // Rank weak tags.
    final masteryMap = await mastery.computeMastery();
    final weakTags = masteryMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weights = <String, double>{};
    for (var i = 0; i < weakTags.length; i++) {
      weights[weakTags[i].key] = (weakTags.length - i).toDouble();
    }

    TheoryMiniLessonNode? best;
    double bestScore = double.negativeInfinity;
    for (final lesson in candidates) {
      final tags = lesson.tags
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty);
      var score = 0.0;
      for (final t in tags) {
        score += weights[t] ?? 0;
      }
      if (score > bestScore) {
        bestScore = score;
        best = lesson;
      }
    }

    if (best != null && bestScore > 0) return best;

    // Fallback to random unlocked lesson.
    final rand = Random();
    return candidates[rand.nextInt(candidates.length)];
  }
}
