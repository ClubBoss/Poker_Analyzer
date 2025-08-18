import '../models/booster_path_log_entry.dart';
import 'booster_path_history_service.dart';
import 'decay_tag_retention_tracker_service.dart';

/// Computes average decay improvement after booster repetitions per tag.
class BoosterEffectivenessAnalyzer {
  final BoosterPathHistoryService history;
  final DecayTagRetentionTrackerService retention;

  const BoosterEffectivenessAnalyzer({
    BoosterPathHistoryService? history,
    this.retention = const DecayTagRetentionTrackerService(),
  }) : history = history ?? BoosterPathHistoryService.instance;

  /// Returns average (initialDecay - postBoosterDecay) for each tag.
  Future<Map<String, double>> computeEffectiveness({DateTime? now}) async {
    final logs = await history.getHistory();
    if (logs.isEmpty) return <String, double>{};

    final grouped = <String, List<BoosterPathLogEntry>>{};
    for (final l in logs) {
      final tag = l.tag.trim().toLowerCase();
      if (tag.isEmpty || l.completedAt == null) continue;
      grouped.putIfAbsent(tag, () => []).add(l);
    }

    final current = now ?? DateTime.now();
    final result = <String, double>{};

    for (final entry in grouped.entries) {
      final events = entry.value
        ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
      if (events.length < 2) continue;
      double total = 0.0;
      for (var i = 1; i < events.length; i++) {
        final prev = events[i - 1].completedAt!;
        final cur = events[i].completedAt!;
        final next = i + 1 < events.length
            ? events[i + 1].completedAt!
            : current;
        final initial = cur.difference(prev).inDays.toDouble();
        final post = i + 1 < events.length
            ? next.difference(cur).inDays.toDouble()
            : await retention.getDecayScore(entry.key, now: current);
        total += initial - post;
      }
      result[entry.key] = total / (events.length - 1);
    }

    return result;
  }
}
