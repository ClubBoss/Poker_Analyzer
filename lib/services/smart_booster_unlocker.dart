import '../models/mistake_tag_history_entry.dart';
import 'mistake_tag_history_service.dart';
import 'mini_lesson_library_service.dart';
import 'tag_mastery_service.dart';
import 'recap_booster_queue.dart';
import 'goal_queue.dart';
import 'theory_priority_gatekeeper_service.dart';
import 'booster_queue_pressure_monitor.dart';
import 'theory_injection_horizon_service.dart';
import 'booster_cooldown_blocker_service.dart';
import 'theory_tag_decay_tracker.dart';

/// Schedules theory boosters based on recent mistakes and weak tags.
class SmartBoosterUnlocker {
  final TagMasteryService mastery;
  final MiniLessonLibraryService lessons;
  final RecapBoosterQueue recapQueue;
  final GoalQueue goalQueue;
  final TheoryTagDecayTracker decayTracker;
  final double decayThreshold;
  final int mistakeLimit;
  final int lessonsPerTag;
  final Future<List<MistakeTagHistoryEntry>> Function({int limit}) _history;

  SmartBoosterUnlocker({
    required this.mastery,
    MiniLessonLibraryService? lessons,
    RecapBoosterQueue? recapQueue,
    GoalQueue? goalQueue,
    TheoryTagDecayTracker? decayTracker,
    Future<List<MistakeTagHistoryEntry>> Function({int limit})? historyLoader,
    this.mistakeLimit = 10,
    this.lessonsPerTag = 2,
    this.decayThreshold = 30.0,
  })  : lessons = lessons ?? MiniLessonLibraryService.instance,
        recapQueue = recapQueue ?? RecapBoosterQueue.instance,
        goalQueue = goalQueue ?? GoalQueue.instance,
        decayTracker = decayTracker ?? TheoryTagDecayTracker(),
        _history = historyLoader ?? MistakeTagHistoryService.getRecentHistory;

  /// Analyzes recent mistakes and mastery to enqueue targeted boosters.
  Future<void> schedule() async {
    if (await BoosterQueuePressureMonitor.instance.isOverloaded()) return;
    if (!await TheoryInjectionHorizonService.instance.canInject('mistake')) {
      return;
    }
    await lessons.loadAll();
    final recent = await _history(limit: mistakeLimit);

    final weak = await mastery.findWeakTags(threshold: 0.7);
    if (weak.isEmpty && recent.isEmpty) return;

    final counts = <String, int>{};
    for (final entry in recent) {
      for (final tag in entry.tags) {
        final key = tag.label.toLowerCase();
        if (weak.contains(key)) {
          counts.update(key, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    final decayScores = await decayTracker.computeDecayScores();
    final priorities = <String, double>{};
    for (final entry in decayScores.entries) {
      if (entry.value > decayThreshold) {
        counts.putIfAbsent(entry.key, () => 0);
        priorities[entry.key] =
            (counts[entry.key]?.toDouble() ?? 0) + entry.value;
      }
    }
    for (final entry in counts.entries) {
      priorities.putIfAbsent(entry.key, () => entry.value.toDouble());
    }
    if (priorities.isEmpty) return;
    final tags = priorities.keys.toList()
      ..sort((a, b) => priorities[b]!.compareTo(priorities[a]!));

    final used = <String>{};
    bool injected = false;
    for (final tag in tags) {
      final lessonList = lessons.findByTags([tag]);
      if (lessonList.isEmpty) continue;
      final urgent = (counts[tag] ?? 0) >= 3;
      int added = 0;
      for (final lesson in lessonList) {
        if (!used.add(lesson.id)) continue;
        if (await TheoryPriorityGatekeeperService.instance.isBlocked(
          lesson.id,
        )) {
          continue;
        }
        if (urgent) {
          if (!await BoosterCooldownBlockerService.instance
              .isCoolingDown('recap')) {
            await recapQueue.add(lesson.id);
          }
        } else {
          if (!await BoosterCooldownBlockerService.instance
              .isCoolingDown('goal')) {
            goalQueue.push(lesson);
          }
        }
        injected = true;
        added++;
        if (added >= lessonsPerTag) break;
      }
    }
    if (injected) {
      await TheoryInjectionHorizonService.instance.markInjected('mistake');
    }
  }
}
