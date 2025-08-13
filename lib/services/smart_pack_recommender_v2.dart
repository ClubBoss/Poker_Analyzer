import '../models/training_attempt.dart';
import 'training_pack_stats_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';
import 'training_path_unlock_service.dart';
import 'weakness_cluster_engine_v2.dart';

class SmartPackRecommenderV2 {
  final TrainingPathUnlockService _unlockService;
  final WeaknessClusterEngine _clusterEngine;

  const SmartPackRecommenderV2({
    TrainingPathUnlockService? unlockService,
    WeaknessClusterEngine? clusterEngine,
  })  : _unlockService = unlockService ?? const TrainingPathUnlockService(),
        _clusterEngine = clusterEngine ?? const WeaknessClusterEngine();

  TrainingPackTemplateV2? recommendNext({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required List<TrainingAttempt> attempts,
  }) {
    if (allPacks.isEmpty) return null;
    final unlocked = _unlockService.getUnlocked(allPacks, stats);
    if (unlocked.isEmpty) return null;

    final clusters = _clusterEngine.computeClusters(
      attempts: attempts,
      allPacks: allPacks,
    );
    final clusterMap = {for (final c in clusters) c.label.toLowerCase(): c};

    TrainingPackTemplateV2? best;
    double bestScore = -1;
    final now = DateTime.now();

    double clusterScoreFor(Set<String> labels) {
      var s = 0.0;
      for (final l in labels) {
        final c = clusterMap[l.toLowerCase()];
        if (c != null) s += 1 - c.avgAccuracy;
      }
      return s;
    }

    for (final p in unlocked) {
      final labels = <String>{
        ...p.tags.map((e) => e.toLowerCase()),
        if (p.category != null) p.category!.toLowerCase(),
      }..removeWhere((e) => e.isEmpty);
      final posLabels = p.positions
          .map(parseHeroPosition)
          .where((pos) => pos != HeroPosition.unknown)
          .map((pos) => pos.label.toLowerCase());
      labels.addAll(posLabels);

      final cScore = clusterScoreFor(labels);

      final stat = stats[p.id];
      final mastery = stat == null ? 1.0 : 1 - stat.accuracy;
      double recency = 1.0;
      if (stat != null) {
        final days = now.difference(stat.last).inDays;
        recency = (days / 7).clamp(0.0, 1.0);
      }

      final score = cScore * 2 + mastery + recency;
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }

    return best;
  }
}
