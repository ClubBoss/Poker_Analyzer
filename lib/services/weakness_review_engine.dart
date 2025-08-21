import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_stats_service.dart';

class WeaknessReviewItem {
  final String packId;
  final String tag;
  final String reason;

  const WeaknessReviewItem({
    required this.packId,
    required this.tag,
    required this.reason,
  });
}

class WeaknessReviewEngine {
  const WeaknessReviewEngine();

  List<WeaknessReviewItem> analyze({
    required List<TrainingAttempt> attempts,
    required Map<String, TrainingPackStat> stats,
    required Map<String, double> tagDeltas,
    required List<TrainingPackTemplateV2> allPacks,
    DateTime? now,
  }) {
    if (allPacks.isEmpty || tagDeltas.isEmpty) return [];
    final current = now ?? DateTime.now();
    const deltaThreshold = -0.3;
    const lookback = Duration(days: 14);
    final recentCutoff = current.subtract(lookback);

    final weakTags = <String, double>{};
    tagDeltas.forEach((tag, delta) {
      if (delta <= deltaThreshold) {
        weakTags[tag.trim().toLowerCase()] = delta;
      }
    });
    if (weakTags.isEmpty) return [];

    final attemptsByPack = <String, List<TrainingAttempt>>{};
    for (final a in attempts) {
      if (a.timestamp.isBefore(recentCutoff)) continue;
      attemptsByPack.putIfAbsent(a.packId, () => []).add(a);
    }

    final scored = <_ScoredItem>[];

    double avgAcc(List<TrainingAttempt> list) {
      if (list.isEmpty) return 1.0;
      var sum = 0.0;
      for (final a in list) {
        sum += a.accuracy;
      }
      return sum / list.length;
    }

    for (final p in allPacks) {
      final stat = stats[p.id];
      if (stat == null) continue;
      if (stat.accuracy >= 0.6) continue;
      if (current.difference(stat.last) > lookback) continue;

      final packTags = [for (final t in p.tags) t.trim().toLowerCase()];
      String? matchedTag;
      double? delta;
      for (final tag in packTags) {
        final d = weakTags[tag];
        if (d != null) {
          matchedTag = tag;
          delta = d;
          break;
        }
      }
      if (matchedTag == null) continue;

      final recentAttempts = attemptsByPack[p.id] ?? [];
      final recAcc =
          recentAttempts.isNotEmpty ? avgAcc(recentAttempts) : stat.accuracy;
      if (recAcc >= 0.6) continue;

      final score = (-delta!) + (0.6 - recAcc);
      scored.add(
        _ScoredItem(
          item: WeaknessReviewItem(
            packId: p.id,
            tag: matchedTag,
            reason: 'weakness in $matchedTag',
          ),
          score: score,
        ),
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final e in scored) e.item];
  }
}

class _ScoredItem {
  final WeaknessReviewItem item;
  final double score;
  const _ScoredItem({required this.item, required this.score});
}
