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
  final Map<String, int> mix;

  const AdaptivePlan({
    required this.clusters,
    required this.estMins,
    required this.tagWeights,
    required this.mix,
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
    String audience = 'regular',
    String format = 'standard',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final wErr = prefs.getDouble('planner.weight.error') ?? 0.55;
    final wDecay = prefs.getDouble('planner.weight.decay') ?? 0.30;
    final wImpact = prefs.getDouble('planner.weight.impact') ?? 0.15;
    var maxTags = prefs.getInt('planner.maxTagsPerPlan') ?? 6;
    switch (format) {
      case 'quick':
        if (maxTags > 2) maxTags = 2;
        break;
      case 'deep':
        maxTags += 2;
        break;
    }
    final padding = prefs.getInt('planner.budgetPaddingMins') ?? 5;

    final skills = await skillService.getSkills(userId);
    final decays = await retention.getAllDecayScores();
    final tagScores = <String, double>{};
    final allTags = {...skills.keys, ...decays.keys};
    for (final tag in allTags) {
      final mastery = skills[tag]?.mastery ?? 0.0;
      final decay = decays[tag] ?? 1.0;
      final rawImpact = await BanditWeightLearner.instance.getImpact(userId, tag);
      final impact = (rawImpact.isNaN
              ? (prefs.getDouble('planner.impact.$tag') ?? 1.0)
              : rawImpact)
          .clamp(0.0, 2.0);
      tagScores[tag] = wErr * (1 - mastery) + wDecay * decay + wImpact * impact;
    }
    final sorted = tagScores.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    // Estimate average durations
    final modules = await store.listModules(userId);
    var boosterSum = 0, boosterCount = 0;
    var assessSum = 0, assessCount = 0;
    var theorySum = 0, theoryCount = 0;
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
        if (d['theoryMins'] != null) {
          theorySum += d['theoryMins']!;
          theoryCount++;
        }
      }
    }
    final boosterAvg =
        boosterCount > 0 ? (boosterSum / boosterCount).round() : 10;
    final assessAvg =
        assessCount > 0 ? (assessSum / assessCount).round() : 8;
    final theoryAvg = theoryCount > 0
        ? (theorySum / theoryCount).round()
        : (prefs.getInt('path.inject.theoryMins') ?? 5);

    final budget = durationMinutes - padding;
    final selected = <String>[];
    for (final e in sorted) {
      if (selected.length >= maxTags) break;
      final mastery = skills[e.key]?.mastery ?? 0.0;
      if (audience == 'novice' && mastery > 0.6) continue;
      selected.add(e.key);
    }

    Map<String, int> mix = mixFor(selected.length, audience, format);
    int estMins = mix['theory']! * theoryAvg + mix['booster']! * boosterAvg + mix['assessment']! * assessAvg;
    while (estMins > budget && selected.isNotEmpty) {
      selected.removeLast();
      mix = mixFor(selected.length, audience, format);
      estMins = mix['theory']! * theoryAvg +
          mix['booster']! * boosterAvg +
          mix['assessment']! * assessAvg;
    }

    final clusters = clusterer.clusterWeakTags(
      weakTags: selected,
      spotTags: const {},
    );

    AutogenStatusDashboardService.instance.update(
      'PlannerV2',
      AutogenStatus(
        isRunning: false,
        currentStage: jsonEncode({
          'audience': audience,
          'format': format,
          'chosenTags': selected,
          'mix': mix,
          'estMins': estMins,
          'budget': budget,
        }),
      ),
    );

    final weights = {for (final t in selected) t: tagScores[t]!};
    return AdaptivePlan(
        clusters: clusters, estMins: estMins, tagWeights: weights, mix: mix);
  }

  static Map<String, int> mixFor(int tagCount, String audience, String format) {
    if (tagCount <= 0) {
      return const {'theory': 0, 'booster': 0, 'assessment': 0};
    }

    final base = <String, Map<String, int>>{
      'novice': const {'theory': 4, 'booster': 3, 'assessment': 1},
      'regular': const {'theory': 2, 'booster': 3, 'assessment': 1},
      'advanced': const {'theory': 1, 'booster': 2, 'assessment': 3},
    };
    final ratios = Map<String, double>.from(
      base[audience] ?? base['regular']!,
    );

    if (format == 'quick') {
      ratios['booster'] = ratios['booster']! * 1.5;
      ratios['assessment'] = ratios['assessment']! * 0.5;
    } else if (format == 'deep') {
      ratios['assessment'] = ratios['assessment']! * 1.5;
    }

    final total = ratios.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) {
      return const {'theory': 0, 'booster': 0, 'assessment': 0};
    }

    final raw = {
      for (final k in ratios.keys) k: (ratios[k]! / total) * tagCount
    };
    final result = {for (final k in raw.keys) k: raw[k]!.floor()};
    var used = result.values.fold<int>(0, (a, b) => a + b);

    if (used < tagCount) {
      final remainder = tagCount - used;
      final frac = {
        for (final k in raw.keys) k: raw[k]! - raw[k]!.floor(),
      };
      final keys = frac.keys.toList()
        ..sort((a, b) => frac[b]!.compareTo(frac[a]!));
      for (var i = 0; i < remainder; i++) {
        final k = keys[i % keys.length];
        result[k] = result[k]! + 1;
      }
    }

    return result;
  }
}

