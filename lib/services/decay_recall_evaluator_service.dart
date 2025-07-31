import 'dart:math' as math;

import 'decay_tag_retention_tracker_service.dart';
import 'tag_mastery_history_service.dart';

/// Evaluates whether decay theory or booster reviews restored mastery.
class DecayRecallEvaluatorService {
  final TagMasteryHistoryService history;
  final DecayTagRetentionTrackerService retention;
  final double improvementThreshold;
  final Duration window;

  const DecayRecallEvaluatorService({
    this.history = const TagMasteryHistoryService(),
    this.retention = const DecayTagRetentionTrackerService(),
    this.improvementThreshold = 0.2,
    this.window = const Duration(days: 3),
  });

  static final Map<String, bool> _cache = {};

  Future<bool> wasRecallSuccessful(String tag) async {
    final key = tag.trim().toLowerCase();
    if (key.isEmpty) return false;

    final theory = await retention.getLastTheoryReview(key);
    final booster = await retention.getLastBoosterCompletion(key);
    DateTime? ts;
    if (theory != null && booster != null) {
      ts = theory.isAfter(booster) ? theory : booster;
    } else {
      ts = theory ?? booster;
    }
    if (ts == null) return false;
    final cacheKey = '$key-${ts.toIso8601String()}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final timeline = await history.getMasteryTimeline(key);
    if (timeline.isEmpty) {
      _cache[cacheKey] = false;
      return false;
    }

    double before = timeline.first.value;
    for (final e in timeline) {
      if (e.key.isBefore(ts)) {
        before = e.value;
      } else {
        break;
      }
    }

    final cutoff = ts.add(window);
    double after = before;
    for (final e in timeline) {
      if (e.key.isAfter(cutoff)) break;
      if (!e.key.isBefore(ts)) after = e.value;
    }

    final success = after - before >= improvementThreshold;
    _cache[cacheKey] = success;
    return success;
  }
}
