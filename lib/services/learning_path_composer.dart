import 'dart:io';
import 'dart:math';

import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';

class PackMeta {
  final String id;
  final List<String> categories;
  final Map<String, double> textureDistribution;
  final double avgTheoryScore;
  final String presetId;
  final int streets;
  final double tagComplexity;
  final double noveltyScore;
  final double decisionDensity;
  final bool theoryHeavy;

  const PackMeta({
    required this.id,
    this.categories = const [],
    this.textureDistribution = const {},
    this.avgTheoryScore = 0.0,
    required this.presetId,
    this.streets = 1,
    this.tagComplexity = 0.0,
    this.noveltyScore = 0.0,
    this.decisionDensity = 0.0,
    this.theoryHeavy = false,
  });
}

class DifficultyWeights {
  final double tags;
  final double decision;
  final double theory;
  final double texture;
  final double novelty;
  const DifficultyWeights({
    this.tags = 0.35,
    this.decision = 0.25,
    this.theory = 0.15,
    this.texture = 0.15,
    this.novelty = 0.10,
  });
}

class DifficultyScorer {
  final DifficultyWeights weights;
  const DifficultyScorer({DifficultyWeights? weights})
      : weights = weights ?? const DifficultyWeights();

  double score(PackMeta meta) {
    final w = weights;
    final tag = meta.tagComplexity;
    final decision = meta.streets / 4.0; // normalize by max 4 streets
    final theory = 1.0 - meta.avgTheoryScore;
    final texture = _entropy(meta.textureDistribution);
    final novelty = meta.noveltyScore;
    return tag * w.tags +
        decision * w.decision +
        theory * w.theory +
        texture * w.texture +
        novelty * w.novelty;
  }

  double _entropy(Map<String, double> dist) {
    if (dist.isEmpty) return 0.0;
    final values = dist.values.toList();
    final total = values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return 0.0;
    final probs = [
      for (final v in values)
        if (v > 0) v / total,
    ];
    if (probs.isEmpty) return 0.0;
    var h = 0.0;
    for (final p in probs) {
      h -= p * (log(p) / ln2);
    }
    final maxH = log(probs.length) / ln2;
    return maxH == 0 ? 0.0 : h / maxH;
  }
}

class LevelQuota {
  final double minDifficulty;
  final double maxDifficulty;
  final int minCategories;
  final double? maxMonotone;
  final double? minDecisionDensity;
  final bool requireTheoryHeavy;
  final bool textureBalanced;
  const LevelQuota({
    required this.minDifficulty,
    required this.maxDifficulty,
    this.minCategories = 0,
    this.maxMonotone,
    this.minDecisionDensity,
    this.requireTheoryHeavy = false,
    this.textureBalanced = false,
  });
}

const Map<int, LevelQuota> defaultQuotas = {
  1: LevelQuota(
    minDifficulty: 0.0,
    maxDifficulty: 0.25,
    minCategories: 3,
    maxMonotone: 0.10,
  ),
  2: LevelQuota(minDifficulty: 0.2, maxDifficulty: 0.45, minCategories: 5),
  3: LevelQuota(
    minDifficulty: 0.4,
    maxDifficulty: 0.65,
    minDecisionDensity: 0.3,
  ),
  4: LevelQuota(
    minDifficulty: 0.6,
    maxDifficulty: 0.8,
    requireTheoryHeavy: true,
  ),
  5: LevelQuota(minDifficulty: 0.75, maxDifficulty: 1.0, textureBalanced: true),
};

class CompositionResult {
  final LearningPathTemplateV2 path;
  final Map<int, List<PackMeta>> assignments;
  const CompositionResult(this.path, this.assignments);
}

class LearningPathComposer {
  final Map<int, LevelQuota> quotas;
  final DifficultyScorer scorer;
  LearningPathComposer({Map<int, LevelQuota>? quotas, DifficultyScorer? scorer})
      : quotas = quotas ?? defaultQuotas,
        scorer = scorer ?? const DifficultyScorer();

  CompositionResult compose(List<PackMeta> packs) {
    final difficulties = {for (final p in packs) p.id: scorer.score(p)};
    final remaining = List<PackMeta>.from(packs);
    final assignments = <int, List<PackMeta>>{};
    for (var level = 1; level <= 5; level++) {
      final quota = quotas[level];
      if (quota == null) continue;
      final selected = _selectForLevel(quota, remaining, difficulties);
      assignments[level] = selected;
      for (final p in selected) {
        remaining.remove(p);
      }
    }
    final path = _buildPath(assignments);
    _logTelemetry(assignments);
    return CompositionResult(path, assignments);
  }

  List<PackMeta> _selectForLevel(
    LevelQuota quota,
    List<PackMeta> avail,
    Map<String, double> difficulties,
  ) {
    final candidates = avail.where((p) {
      final d = difficulties[p.id] ?? 0.0;
      if (d < quota.minDifficulty || d > quota.maxDifficulty) return false;
      if (quota.maxMonotone != null) {
        final mono = p.textureDistribution['monotone'] ?? 0.0;
        if (mono > quota.maxMonotone!) return false;
      }
      if (quota.minDecisionDensity != null &&
          p.decisionDensity < quota.minDecisionDensity!) return false;
      if (quota.requireTheoryHeavy && !p.theoryHeavy) return false;
      return true;
    }).toList();

    final selected = <PackMeta>[];
    final covered = <String>{};
    while (covered.length < quota.minCategories && candidates.isNotEmpty) {
      PackMeta? best;
      var bestGain = -1;
      candidates.sort((a, b) => a.id.compareTo(b.id));
      for (final p in candidates) {
        final gain = p.categories.where((c) => !covered.contains(c)).length;
        if (gain > bestGain) {
          best = p;
          bestGain = gain;
        }
      }
      if (best == null || bestGain <= 0) break;
      selected.add(best);
      covered.addAll(best.categories);
      candidates.remove(best);
    }
    return selected;
  }

  LearningPathTemplateV2 _buildPath(Map<int, List<PackMeta>> assignments) {
    final stages = <LearningPathStageModel>[];
    var order = 0;
    String? prevId;
    final levels = assignments.keys.toList()..sort();
    for (final level in levels) {
      final packs = assignments[level] ?? const [];
      for (var i = 0; i < packs.length; i++) {
        final p = packs[i];
        final stageId = 'L${level}P$i';
        stages.add(
          LearningPathStageModel(
            id: stageId,
            title: 'Pack ${p.id}',
            description: '',
            packId: p.id,
            requiredAccuracy: 0.7,
            requiredHands: 20,
            unlockAfter: prevId == null ? const [] : [prevId!],
            order: order++,
            tags: ['L$level'],
          ),
        );
        prevId = stageId;
      }
    }
    return LearningPathTemplateV2(
      id: 'cash_path_v1',
      title: 'Cash Path v1',
      description: 'Auto-composed path',
      stages: stages,
      tags: const ['auto'],
    );
  }

  void _logTelemetry(Map<int, List<PackMeta>> assignments) {
    final totalLevels = assignments.length;
    final totalPacks = assignments.values.fold<int>(0, (a, b) => a + b.length);
    final file = File('autogen_report.log');
    final msg =
        '[${DateTime.now().toIso8601String()}] Path: $totalLevels/5 levels ready • $totalPacks packs\n';
    file.writeAsStringSync(msg, mode: FileMode.append);
    AutogenStatusDashboardService.instance.update(
      'PathComposer',
      AutogenStatus(
        isRunning: false,
        currentStage: 'Path: $totalLevels/5 levels ready • $totalPacks packs',
      ),
    );
  }
}
