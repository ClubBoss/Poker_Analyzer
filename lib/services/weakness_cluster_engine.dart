import '../models/training_result.dart';

class WeaknessCluster {
  final String tag;
  final String reason;
  final double severity;

  WeaknessCluster({
    required this.tag,
    required this.reason,
    required this.severity,
  });
}

class WeaknessClusterEngine {
  WeaknessClusterEngine();

  List<WeaknessCluster> detectWeaknesses({
    required List<TrainingResult> results,
    required Map<String, double> tagMastery,
  }) {
    final attempts = <String, int>{};
    final mistakes = <String, int>{};
    final evSum = <String, double>{};
    final evCount = <String, int>{};

    for (final r in results) {
      final miss = r.total - r.correct;
      for (final t in r.tags) {
        final tag = t.trim().toLowerCase();
        if (tag.isEmpty) continue;
        attempts.update(tag, (v) => v + r.total, ifAbsent: () => r.total);
        mistakes.update(tag, (v) => v + miss, ifAbsent: () => miss);
        if (r.evDiff != null) {
          evSum.update(tag, (v) => v + r.evDiff!, ifAbsent: () => r.evDiff!);
          evCount.update(tag, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    final tags = <String>{...attempts.keys, ...tagMastery.keys};
    final clusters = <WeaknessCluster>[];

    for (final tag in tags) {
      final plays = attempts[tag] ?? 0;
      final miss = mistakes[tag] ?? 0;
      final acc = plays > 0 ? (plays - miss) / plays : 1.0;
      final avgEv = evCount.containsKey(tag)
          ? evSum[tag]! / evCount[tag]!
          : null;
      final mastery = tagMastery[tag] ?? 1.0;

      double bestScore = 0;
      String? reason;

      if (plays >= 5 && miss > 0) {
        final rate = miss / plays;
        if (rate > bestScore) {
          bestScore = rate;
          reason = 'many mistakes';
        }
      }

      if (avgEv != null && avgEv < 0) {
        final score = -avgEv; // higher loss -> higher severity
        if (score > bestScore) {
          bestScore = score;
          reason = 'low EV';
        }
      }

      if (mastery < 0.6) {
        final score = 0.6 - mastery;
        if (score > bestScore) {
          bestScore = score;
          reason = 'low mastery';
        }
      }

      if (reason != null && bestScore > 0) {
        clusters.add(
          WeaknessCluster(tag: tag, reason: reason, severity: bestScore),
        );
      }
    }

    clusters.sort((a, b) => b.severity.compareTo(a.severity));
    return clusters;
  }

  List<WeaknessCluster> topWeaknesses({
    required List<TrainingResult> results,
    required Map<String, double> tagMastery,
    int count = 3,
  }) {
    final all = detectWeaknesses(results: results, tagMastery: tagMastery);
    return all.take(count).toList();
  }
}
