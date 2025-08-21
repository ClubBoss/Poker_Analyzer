import 'package:collection/collection.dart';

import '../models/training_attempt.dart';
import '../models/learning_path_template_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';
import 'training_pack_stats_service.dart';
import 'training_path_unlock_service.dart';
import 'weakness_cluster_engine_v2.dart';
import 'learning_path_advancer.dart';

class RecommendedPack {
  final String packId;
  final String reason;
  const RecommendedPack({required this.packId, required this.reason});
}

class SmartPackRecommender {
  final WeaknessClusterEngine _clusterEngine;
  final LearningPathAdvancer _advancer;
  final TrainingPathUnlockService _unlockService;

  const SmartPackRecommender({
    WeaknessClusterEngine? clusterEngine,
    LearningPathAdvancer? advancer,
    TrainingPathUnlockService? unlockService,
  })  : _clusterEngine = clusterEngine ?? const WeaknessClusterEngine(),
        _advancer = advancer ?? const LearningPathAdvancer(),
        _unlockService = unlockService ?? const TrainingPathUnlockService();

  List<RecommendedPack> getTopRecommendations({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required List<TrainingAttempt> attempts,
    LearningPathTemplateV2? path,
    DateTime? now,
    int count = 3,
  }) {
    if (allPacks.isEmpty) return [];
    final current = now ?? DateTime.now();
    final unlocked = _unlockService.getUnlocked(allPacks, stats);
    if (unlocked.isEmpty) return [];

    final clusters = _clusterEngine.computeClusters(
      attempts: attempts,
      allPacks: allPacks,
    );
    final clusterMap = {for (final c in clusters) c.label.toLowerCase(): c};

    String? pathPackId;
    String? pathReason;
    if (path != null) {
      final next = _advancer.getNextAction(
        allPacks: allPacks,
        stats: stats,
        attempts: attempts,
        path: path,
        now: current,
      );
      if (next != null) {
        final stage = path.stages.firstWhereOrNull((s) => s.id == next.stageId);
        pathPackId = stage?.packId;
        pathReason = next.reason;
      }
    }

    final attemptsByPack = <String, List<TrainingAttempt>>{};
    for (final a in attempts) {
      attemptsByPack.putIfAbsent(a.packId, () => []).add(a);
    }

    final entries = <_PackScore>[];

    for (final p in unlocked) {
      final stat = stats[p.id];
      if (stat != null && stat.accuracy >= 0.9) continue;

      final labels = <String>{
        ...p.tags.map((e) => e.toLowerCase()),
        if (p.category != null) p.category!.toLowerCase(),
      }..removeWhere((e) => e.isEmpty);
      labels.addAll(
        p.positions
            .map(parseHeroPosition)
            .where((pos) => pos != HeroPosition.unknown)
            .map((pos) => pos.label.toLowerCase()),
      );

      double clusterScore = 0;
      String? clusterLabel;
      for (final l in labels) {
        final c = clusterMap[l];
        if (c != null) {
          clusterScore += 1 - c.avgAccuracy;
          clusterLabel ??= c.label;
        }
      }

      final recentMistake = attemptsByPack[p.id]?.any(
            (a) =>
                a.accuracy < 0.7 && current.difference(a.timestamp).inDays <= 7,
          ) ??
          false;
      final decayed = stat != null && current.difference(stat.last).inDays >= 7;

      double score =
          clusterScore * 2 + (stat == null ? 1.0 : 1 - stat.accuracy);
      if (recentMistake || decayed) score += 1.5;
      String reason = 'Next Stage';

      if (p.id == pathPackId) {
        score += 5;
        reason = pathReason ?? 'Next Stage';
      } else if (clusterScore > 0) {
        reason = 'Weakness: ${clusterLabel ?? ''}'.trim();
      } else if (recentMistake || decayed) {
        reason = 'Confidence Decay';
      }

      entries.add(_PackScore(packId: p.id, score: score, reason: reason));
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries
        .take(count)
        .map((e) => RecommendedPack(packId: e.packId, reason: e.reason))
        .toList();
  }
}

class _PackScore {
  final String packId;
  final double score;
  final String reason;
  const _PackScore({
    required this.packId,
    required this.score,
    required this.reason,
  });
}
