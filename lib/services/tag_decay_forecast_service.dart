import 'dart:math' as math;

import 'decay_session_tag_impact_recorder.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'inbox_booster_tuner_service.dart';
import 'recall_success_logger_service.dart';

class TagDecayStats {
  final String tag;
  final DateTime? lastTrained;
  final Duration timeSinceLast;
  final Duration averageInterval;
  final double intervalStd;
  final DateTime? nextReview;

  const TagDecayStats({
    required this.tag,
    this.lastTrained,
    this.timeSinceLast = Duration.zero,
    this.averageInterval = Duration.zero,
    this.intervalStd = 0,
    this.nextReview,
  });
}

class TagDecayForecastService {
  final DecayTagRetentionTrackerService retention;
  final RecallSuccessLoggerService logger;
  final InboxBoosterTunerService tuner;

  const TagDecayForecastService({
    this.retention = const DecayTagRetentionTrackerService(),
    RecallSuccessLoggerService? logger,
    InboxBoosterTunerService? tuner,
  })  : logger = logger ?? RecallSuccessLoggerService.instance,
        tuner = tuner ?? InboxBoosterTunerService.instance;

  Future<Map<String, TagDecayStats>> summarize({DateTime? now}) async {
    final events = await DecaySessionTagImpactRecorder.instance.loadAllEvents();
    final current = now ?? DateTime.now();
    final grouped = <String, List<DateTime>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.tag, () => []).add(e.timestamp);
    }
    final result = <String, TagDecayStats>{};
    for (final entry in grouped.entries) {
      final times = entry.value..sort();
      final last = times.isNotEmpty ? times.last : null;
      final intervals = <double>[];
      for (var i = 1; i < times.length; i++) {
        intervals
            .add(times[i].difference(times[i - 1]).inMilliseconds / 86400000);
      }
      final avg = intervals.isEmpty
          ? 0.0
          : intervals.reduce((a, b) => a + b) / intervals.length;
      final std = intervals.isEmpty
          ? 0.0
          : math.sqrt(intervals
                  .map((d) => math.pow(d - avg, 2))
                  .reduce((a, b) => a + b) /
              intervals.length);
      final next = last?.add(Duration(days: avg.round()));
      final sinceLast = last != null ? current.difference(last) : Duration.zero;
      result[entry.key] = TagDecayStats(
        tag: entry.key,
        lastTrained: last,
        timeSinceLast: sinceLast,
        averageInterval: Duration(days: avg.round()),
        intervalStd: std,
        nextReview: next,
      );
    }
    return result;
  }

  /// Returns current decay scores for all known tags normalized 0.0-1.0.
  Future<Map<String, double>> getAllForecasts() async {
    final successes = await logger.getSuccesses();
    final fromLogs = successes
        .map((e) => e.tag.trim().toLowerCase())
        .where((t) => t.isNotEmpty);
    final boost = await tuner.computeTagBoostScores();
    final fromBoost = boost.keys
        .map((e) => e.trim().toLowerCase())
        .where((t) => t.isNotEmpty);
    final tags = {...fromLogs, ...fromBoost};
    final result = <String, double>{};
    for (final tag in tags) {
      final score = await retention.getDecayScore(tag);
      result[tag] = (score / 100).clamp(0.0, 1.0);
    }
    return result;
  }

  /// Returns tags with normalized decay above [threshold], sorted by severity.
  Future<List<String>> getCriticalTags({double threshold = 0.8}) async {
    final forecasts = await getAllForecasts();
    final entries = forecasts.entries.where((e) => e.value > threshold).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries) e.key];
  }
}
