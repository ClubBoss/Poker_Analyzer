import 'dart:async';

import 'completed_training_pack_registry.dart';

/// Aggregated statistics of completed training sessions.
class CompletionStats {
  final int totalSessions;
  final double averageAccuracy;
  final Duration? averageDuration;

  CompletionStats({
    required this.totalSessions,
    required this.averageAccuracy,
    this.averageDuration,
  });
}

/// Summarizes completed training sessions using stored fingerprints.
class TrainingSessionCompletionStatsService {
  final CompletedTrainingPackRegistry registry;

  TrainingSessionCompletionStatsService({
    CompletedTrainingPackRegistry? registry,
  }) : registry = registry ?? CompletedTrainingPackRegistry();

  /// Computes aggregated statistics across all completed sessions.
  Future<CompletionStats> computeStats() async {
    final fingerprints = await registry.listCompletedFingerprints();
    int total = 0;
    double accuracySum = 0;
    int accuracyCount = 0;
    int durationSumMs = 0;
    int durationCount = 0;

    for (final fp in fingerprints) {
      final data = await registry.getCompletedPackData(fp);
      if (data == null) continue;
      total++;

      final acc = data['accuracy'];
      if (acc is num) {
        accuracySum += acc.toDouble();
        accuracyCount++;
      }

      final dur = data['durationMs'] ?? data['duration'];
      if (dur is num) {
        durationSumMs += dur.toInt();
        durationCount++;
      } else if (dur is String) {
        // Attempt to parse numeric string or ISO8601 duration.
        final parsed = int.tryParse(dur);
        if (parsed != null) {
          durationSumMs += parsed;
          durationCount++;
        } else {
          try {
            final iso = Duration.parse(dur);
            durationSumMs += iso.inMilliseconds;
            durationCount++;
          } catch (_) {}
        }
      }
    }

    final avgAcc = accuracyCount > 0 ? accuracySum / accuracyCount : 0;
    final avgDur = durationCount > 0
        ? Duration(milliseconds: (durationSumMs / durationCount).round())
        : null;

    return CompletionStats(
      totalSessions: total,
      averageAccuracy: avgAcc,
      averageDuration: avgDur,
    );
  }
}
