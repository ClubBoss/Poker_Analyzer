import '../models/tag_decay_summary.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'recall_success_logger_service.dart';
import 'inbox_booster_tuner_service.dart';

/// Provides aggregated decay diagnostics across all known tags.
class RecallTagDecaySummaryService {
  final DecayTagRetentionTrackerService retention;
  final RecallSuccessLoggerService logger;
  final InboxBoosterTunerService tuner;

  const RecallTagDecaySummaryService({
    DecayTagRetentionTrackerService? retention,
    RecallSuccessLoggerService? logger,
    InboxBoosterTunerService? tuner,
  })  : retention = retention ?? const DecayTagRetentionTrackerService(),
        logger = logger ?? RecallSuccessLoggerService.instance,
        tuner = tuner ?? InboxBoosterTunerService.instance;

  /// Returns summary metrics for all known tags.
  Future<TagDecaySummary> getSummary() async {
    final successes = await logger.getSuccesses();
    final fromLogs = successes
        .map((e) => e.tag.trim().toLowerCase())
        .where((t) => t.isNotEmpty);
    final boostScores = await tuner.computeTagBoostScores();
    final fromBoost = boostScores.keys
        .map((e) => e.trim().toLowerCase())
        .where((t) => t.isNotEmpty);

    final allTags = {...fromLogs, ...fromBoost};
    final scores = <String, double>{};
    double total = 0.0;
    int countCritical = 0;
    int countWarning = 0;

    for (final tag in allTags) {
      final score = await retention.getDecayScore(tag);
      scores[tag] = score;
      total += score;
      if (score > 60) countCritical++;
      if (score > 30) countWarning++;
    }

    final avg = allTags.isNotEmpty ? total / allTags.length : 0.0;
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostDecayed = [for (final e in sorted.take(5)) e.key];

    return TagDecaySummary(
      avgDecay: avg,
      countCritical: countCritical,
      countWarning: countWarning,
      mostDecayedTags: mostDecayed,
    );
  }
}
