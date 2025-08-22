import 'dart:math' as math;

import 'tag_mastery_service.dart';

class RetentionEvaluator {
  RetentionEvaluator();

  double evaluate({
    required double mastery,
    required DateTime? lastTrained,
    required double lastAccuracy,
    DateTime? now,
  }) {
    if (lastTrained == null) return mastery;
    final current = now ?? DateTime.now();
    final daysSince = current.difference(lastTrained).inDays.toDouble();
    final qualityFactor = 1 - lastAccuracy.clamp(0.0, 1.0);
    final decay = math.exp(-daysSince * qualityFactor);
    return (mastery * decay).clamp(0.0, 1.0);
  }
}

class TagRetentionTracker {
  final TagMasteryService mastery;
  final RetentionEvaluator evaluator;
  TagRetentionTracker({
    required this.mastery,
    RetentionEvaluator? evaluator,
  }) : evaluator = evaluator ?? const RetentionEvaluator();

  Future<List<String>> getDecayedTags({
    double threshold = 0.75,
    DateTime? now,
  }) async {
    final map = await mastery.computeMastery();
    final last = await mastery.getLastTrained();
    final acc = await mastery.getLastAccuracy();
    final result = <String>[];
    map.forEach((tag, value) {
      final eff = evaluator.evaluate(
        mastery: value,
        lastTrained: last[tag],
        lastAccuracy: acc[tag] ?? 1.0,
        now: now,
      );
      if (eff < threshold) result.add(tag);
    });
    return result;
  }
}
