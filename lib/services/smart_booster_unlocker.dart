import '../models/mistake_tag_history_entry.dart';
import '../models/theory_mini_lesson_node.dart';
import 'mistake_tag_history_service.dart';
import 'mini_lesson_library_service.dart';
import 'tag_mastery_service.dart';
import 'recap_booster_queue.dart';
import 'goal_queue.dart';
import 'theory_priority_gatekeeper_service.dart';

/// Schedules theory boosters based on recent mistakes and weak tags.
class SmartBoosterUnlocker {
  final TagMasteryService mastery;
  final MiniLessonLibraryService lessons;
  final RecapBoosterQueue recapQueue;
  final GoalQueue goalQueue;
  final int mistakeLimit;
  final int lessonsPerTag;
  final Future<List<MistakeTagHistoryEntry>> Function({int limit}) _history;

  SmartBoosterUnlocker({
    required this.mastery,
    MiniLessonLibraryService? lessons,
    RecapBoosterQueue? recapQueue,
    GoalQueue? goalQueue,
    Future<List<MistakeTagHistoryEntry>> Function({int limit})? historyLoader,
    this.mistakeLimit = 10,
    this.lessonsPerTag = 2,
  })  : lessons = lessons ?? MiniLessonLibraryService.instance,
        recapQueue = recapQueue ?? RecapBoosterQueue.instance,
        goalQueue = goalQueue ?? GoalQueue.instance,
        _history = historyLoader ?? MistakeTagHistoryService.getRecentHistory;

  /// Analyzes recent mistakes and mastery to enqueue targeted boosters.
  Future<void> schedule() async {
    await lessons.loadAll();
    final recent = await _history(limit: mistakeLimit);
    if (recent.isEmpty) return;

    final weak = await mastery.findWeakTags(threshold: 0.7);
    if (weak.isEmpty) return;

    final counts = <String, int>{};
    for (final entry in recent) {
      for (final tag in entry.tags) {
        final key = tag.label.toLowerCase();
        if (weak.contains(key)) {
          counts.update(key, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
    if (counts.isEmpty) return;

    final tags = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final used = <String>{};
    for (final tag in tags) {
      final lessonList = lessons.findByTags([tag]);
      if (lessonList.isEmpty) continue;
      final urgent = (counts[tag] ?? 0) >= 3;
      int added = 0;
      for (final lesson in lessonList) {
        if (!used.add(lesson.id)) continue;
        if (await TheoryPriorityGatekeeperService.instance
            .isBlocked(lesson.id)) {
          continue;
        }
        if (urgent) {
          await recapQueue.add(lesson.id);
        } else {
          goalQueue.push(lesson);
        }
        added++;
        if (added >= lessonsPerTag) break;
      }
    }
  }
}
