import '../models/scheduled_booster_entry.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'recall_success_logger_service.dart';
import 'inbox_booster_tuner_service.dart';

/// Schedules recall boosters based on decay intensity and past effectiveness.
class SmartRecallBoosterScheduler {
  final DecayTagRetentionTrackerService retention;
  final RecallSuccessLoggerService logger;
  final InboxBoosterTunerService tuner;

  SmartRecallBoosterScheduler({
    DecayTagRetentionTrackerService? retention,
    RecallSuccessLoggerService? logger,
    InboxBoosterTunerService? tuner,
  }) : retention = retention ?? const DecayTagRetentionTrackerService(),
       logger = logger ?? RecallSuccessLoggerService.instance,
       tuner = tuner ?? InboxBoosterTunerService.instance;

  /// Returns upcoming boosters ordered by priority.
  Future<List<ScheduledBoosterEntry>> getNextBoosters({int max = 5}) async {
    if (max <= 0) return <ScheduledBoosterEntry>[];
    final boostScores = await tuner.computeTagBoostScores();
    final logEntries = await logger.getSuccesses();
    final successMap = <String, int>{};
    for (final e in logEntries) {
      successMap.update(e.tag, (v) => v + 1, ifAbsent: () => 1);
    }

    final tags = <String>{...boostScores.keys, ...successMap.keys};
    final result = <ScheduledBoosterEntry>[];
    for (final tag in tags) {
      final decay = await retention.getDecayScore(tag);
      final successes = successMap[tag] ?? 0;
      final weight = boostScores[tag] ?? 1.0;

      double priority = decay * weight / (successes + 1);
      if (decay > 60 && successes <= 1) {
        priority += 100;
      } else if (decay > 30 && successes == 0) {
        priority += 50;
      }
      result.add(ScheduledBoosterEntry(tag: tag, priorityScore: priority));
    }

    result.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return result.take(max).toList();
  }
}
