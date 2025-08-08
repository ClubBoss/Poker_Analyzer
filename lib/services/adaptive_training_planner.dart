import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auto_skill_gap_clusterer.dart';
import 'autogen_status_dashboard_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'learning_path_store.dart';
import 'user_skill_model_service.dart';
import '../models/autogen_status.dart';
import 'bandit_weight_learner.dart';

class AdaptivePlan {
  final List<SkillTagCluster> clusters;
  final int estMins;
  final Map<String, double> tagWeights;

  const AdaptivePlan({
    required this.clusters,
    required this.estMins,
    required this.tagWeights,
  });
}

class AdaptiveTrainingPlanner {
  final UserSkillModelService skillService;
  final DecayTagRetentionTrackerService retention;
  final AutoSkillGapClusterer clusterer;
  final LearningPathStore store;

  const AdaptiveTrainingPlanner({
    UserSkillModelService? skillService,
    DecayTagRetentionTrackerService? retention,
    AutoSkillGapClusterer? clusterer,
    LearningPathStore? store,
  })  : skillService = skillService ?? UserSkillModelService.instance,
        retention = retention ?? const DecayTagRetentionTrackerService(),
        clusterer = clusterer ?? const AutoSkillGapClusterer(),
        store = store ?? const LearningPathStore();

  Future<AdaptivePlan> plan({
    required String userId,
    required int durationMinutes,
    String? audience,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final wErr = prefs.getDouble('planner.weight.error') ?? 0.55;
    final wDecay = prefs.getDouble('planner.weight.decay') ?? 0.30;
    final wImpact = prefs.getDouble('planner.weight.impact') ?? 0.15;
    final maxTags = prefs.getInt('planner.maxTagsPerPlan') ?? 6;
    final padding = prefs.getInt('planner.budgetPaddingMins') ?? 5;

    final skills = await skillService.getSkills(userId);
    final decays = await retention.getAllDecayScores();
    final tagScores = <String, double>{};
    final impacts = await BanditWeightLearner.instance.getAllImpacts(userId);
    final allTags = {...skills.keys, ...decays.keys};
    for (final tag in allTags) {
      final mastery = skills[tag]?.mastery ?? 0.0;
      final decay = decays[tag] ?? 1.0;
      final impact = (impacts[tag] ??
              prefs.getDouble('planner.impact.$tag') ??
              1.0)
          .clamp(0.0, 2.0);
      tagScores[tag] =
          wErr * (1 - mastery) + wDecay * decay + wImpact * impact;
    }
    final sorted = tagScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Estimate average durations
    final modules = await store.listModules(userId);
    var boosterSum = 0, boosterCount = 0;
    var assessSum = 0, assessCount = 0;
    for (final m in modules) {
      final d = m.itemsDurations;
      if (d != null) {
        if (d['boosterMins'] != null) {
          boosterSum += d['boosterMins']!;
          boosterCount++;
        }
        if (d['assessmentMins'] != null) {
          assessSum += d['assessmentMins']!;
          assessCount++;
        }
      }
    }
    final boosterAvg =
        boosterCount > 0 ? (boosterSum / boosterCount).round() : 10;
    final assessAvg =
        assessCount > 0 ? (assessSum / assessCount).round() : 8;
    final perTag = boosterAvg + assessAvg;
    final budget = durationMinutes - padding;
    var used = 0;
    final selected = <String>[];
    for (final e in sorted) {
      if (selected.length >= maxTags) break;
      if (used + perTag > budget) continue;
      selected.add(e.key);
      used += perTag;
    }
    final clusters = clusterer.clusterWeakTags(
      weakTags: selected,
      spotTags: const {},
    );

    AutogenStatusDashboardService.instance.update(
      'AdaptivePlanner',
      AutogenStatus(
        isRunning: false,
        currentStage: jsonEncode({
          'budget': durationMinutes,
          'tags': selected,
          'clusters': clusters.length,
        }),
      ),
    );

    final weights = {
      for (final t in selected) t: tagScores[t]!,
    };
    return AdaptivePlan(clusters: clusters, estMins: used, tagWeights: weights);
  }
}

