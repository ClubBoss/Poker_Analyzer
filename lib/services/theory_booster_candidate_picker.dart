import '../models/theory_mini_lesson_node.dart';
import 'mistake_tag_history_service.dart';
import 'mini_lesson_library_service.dart';

/// Picks theory mini lessons for booster reinforcement based on recent mistakes.
class TheoryBoosterCandidatePicker {
  final MiniLessonLibraryService library;

  TheoryBoosterCandidatePicker({
    this.library = MiniLessonLibraryService.instance,
  });

  /// Returns up to 3 mini lessons linked to repeated recent mistakes.
  Future<List<TheoryMiniLessonNode>> getTopBoosterCandidates() async {
    await library.loadAll();
    final history = await MistakeTagHistoryService.getRecentHistory(limit: 50);
    if (history.isEmpty) return <TheoryMiniLessonNode>[];

    final tagCounts = <String, int>{};
    final tagSessions = <String, Set<String>>{};
    final tagLast = <String, DateTime>{};

    for (final entry in history) {
      for (final tag in entry.tags) {
        final key = tag.label.toLowerCase();
        tagCounts.update(key, (v) => v + 1, ifAbsent: () => 1);
        tagSessions.putIfAbsent(key, () => <String>{}).add(entry.packId);
        final last = tagLast[key];
        if (last == null || entry.timestamp.isAfter(last)) {
          tagLast[key] = entry.timestamp;
        }
      }
    }

    final candidates = <_Candidate>[];
    final now = DateTime.now();

    for (final tag in tagCounts.keys) {
      final count = tagCounts[tag] ?? 0;
      final sessions = tagSessions[tag]?.length ?? 0;
      if (count < 3 || sessions < 2) continue;
      final last = tagLast[tag] ?? now;
      final days = now.difference(last).inDays.clamp(0, 30);
      final recency = 1 - days / 30;
      final score = count + recency;
      final lessons = library.findByTags([tag]);
      for (final l in lessons) {
        candidates.add(_Candidate(l, score));
      }
    }

    if (candidates.isEmpty) return <TheoryMiniLessonNode>[];

    final map = <String, _Candidate>{};
    for (final c in candidates) {
      final existing = map[c.lesson.id];
      if (existing == null || c.score > existing.score) {
        map[c.lesson.id] = c;
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return [for (final c in sorted.take(3)) c.lesson];
  }
}

class _Candidate {
  final TheoryMiniLessonNode lesson;
  final double score;
  _Candidate(this.lesson, this.score);
}
