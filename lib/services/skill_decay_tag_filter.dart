import 'mini_lesson_library_service.dart';
import 'recap_booster_queue.dart';
import 'goal_queue.dart';
import 'tag_mastery_history_service.dart';

/// Filters out tags that were recently reinforced or are already queued.
class SkillDecayTagFilter {
  final TagMasteryHistoryService history;
  final MiniLessonLibraryService lessons;
  final RecapBoosterQueue recapQueue;
  final GoalQueue goalQueue;
  final Duration recent;

  SkillDecayTagFilter({
    required this.history,
    MiniLessonLibraryService? lessons,
    RecapBoosterQueue? recapQueue,
    GoalQueue? goalQueue,
    this.recent = const Duration(days: 3),
  }) : lessons = lessons ?? MiniLessonLibraryService.instance,
       recapQueue = recapQueue ?? RecapBoosterQueue.instance,
       goalQueue = goalQueue ?? GoalQueue.instance;

  /// Returns [tags] excluding those recently reinforced or already queued.
  Future<List<String>> filter(List<String> tags, {DateTime? now}) async {
    if (tags.isEmpty) return [];
    await lessons.loadAll();
    final current = now ?? DateTime.now();
    final hist = await history.getHistory();

    // Collect queued tags from recap and goal queues.
    final queued = <String>{};
    for (final id in recapQueue.getQueue()) {
      final lesson = lessons.getById(id);
      if (lesson != null) {
        queued.addAll(lesson.tags.map((e) => e.toLowerCase()));
      }
    }
    for (final lesson in goalQueue.getQueue()) {
      queued.addAll(lesson.tags.map((e) => e.toLowerCase()));
    }

    final result = <String>[];
    for (final t in tags) {
      final tag = t.toLowerCase();
      final entries = hist[tag];
      final last = entries == null || entries.isEmpty
          ? null
          : entries.last.date;
      final recentlyReinforced =
          last != null && current.difference(last) < recent;
      if (recentlyReinforced || queued.contains(tag)) continue;
      result.add(tag);
    }
    return result;
  }
}
