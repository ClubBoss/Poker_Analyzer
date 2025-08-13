import 'package:collection/collection.dart';

import '../models/training_attempt.dart';
import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_stats_service.dart';
import 'weakness_cluster_engine_v2.dart';

class AdaptiveTrainingPathEngine {
  final WeaknessClusterEngine clusterEngine;

  const AdaptiveTrainingPathEngine(
      {this.clusterEngine = const WeaknessClusterEngine()});

  /// Returns IDs of stages unlocked based on completed prerequisites and
  /// player's weaknesses.
  List<String> getUnlockedStageIds({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required List<TrainingAttempt> attempts,
    required LearningPathTemplateV2 path,
  }) {
    final mastery = _computeTagMastery(allPacks, stats);
    final clusters = clusterEngine.computeClusters(
      attempts: attempts,
      allPacks: allPacks,
    );
    final weakLabels = <String>{
      for (final c in clusters) c.label.toLowerCase(),
      for (final e in mastery.entries)
        if (e.value < 0.8) e.key.toLowerCase(),
    };

    final prereq = _buildPrereq(path);
    final completed = <String>{};
    for (final s in path.stages) {
      final acc = stats[s.packId]?.accuracy ?? 0.0;
      if (acc >= 90) completed.add(s.id);
    }

    final unlocked = <String>{};
    void tryUnlock(LearningPathStageModel stage) {
      if (unlocked.contains(stage.id)) return;
      final req = prereq[stage.id] ?? const <String>{};
      if (!req.every(completed.contains)) return;
      final labels = <String>{...stage.tags};
      final pack = allPacks.firstWhereOrNull((p) => p.id == stage.packId);
      if (pack != null) {
        labels.addAll(pack.tags);
        labels.addAll(pack.positions);
      }
      bool hasWeakness = labels.isEmpty;
      for (final l in labels) {
        if (weakLabels.contains(l.toLowerCase())) {
          hasWeakness = true;
          break;
        }
      }
      if (hasWeakness || completed.contains(stage.id)) {
        unlocked.add(stage.id);
        for (final next in stage.unlocks) {
          final nextStage = path.stages.firstWhereOrNull((e) => e.id == next);
          if (nextStage != null) tryUnlock(nextStage);
        }
      }
    }

    for (final s in path.entryStages) {
      tryUnlock(s);
    }

    return unlocked.toList();
  }

  bool isStageUnlocked(
    String stageId, {
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required List<TrainingAttempt> attempts,
    required LearningPathTemplateV2 path,
  }) {
    final ids = getUnlockedStageIds(
      allPacks: allPacks,
      stats: stats,
      attempts: attempts,
      path: path,
    );
    return ids.contains(stageId);
  }

  Map<String, double> _computeTagMastery(
    List<TrainingPackTemplateV2> packs,
    Map<String, TrainingPackStat> stats,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final p in packs) {
      final acc = stats[p.id]?.accuracy ?? 0.0;
      for (final t in [...p.tags, ...p.positions]) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        sums.update(key, (v) => v + acc, ifAbsent: () => acc);
        counts.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final map = <String, double>{};
    sums.forEach((k, v) {
      final c = counts[k]!;
      map[k] = v / c;
    });
    return map;
  }

  Map<String, Set<String>> _buildPrereq(LearningPathTemplateV2 path) {
    final map = <String, Set<String>>{};
    for (final s in path.stages) {
      for (final next in s.unlocks) {
        map.putIfAbsent(next, () => <String>{}).add(s.id);
      }
    }
    return map;
  }
}
