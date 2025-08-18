import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

import '../models/injected_path_module.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/autogen_status.dart';
import 'adaptive_training_planner.dart';
import 'assessment_pack_synthesizer.dart';
import 'auto_format_selector.dart';
import 'autogen_status_dashboard_service.dart';
import 'learning_path_store.dart';
import 'pack_quality_gatekeeper_service.dart';
import 'targeted_pack_booster_engine.dart';

class _PackInfo {
  final TrainingPackTemplateV2 template;
  final int mins;
  final double ev;
  _PackInfo(this.template, this.mins, this.ev);
}

/// Executes an [AdaptivePlan] by generating boosters and assessments,
/// enforcing quality gates, deduplicating and persisting modules
/// within a given time budget.
class AdaptivePlanExecutor {
  final TargetedPackBoosterEngine boosterEngine;
  final AutoFormatSelector formatSelector;
  final PackQualityGatekeeperService gatekeeper;
  final LearningPathStore store;
  final AssessmentPackSynthesizer synthesizer;
  final AutogenStatusDashboardService dashboard;

  const AdaptivePlanExecutor({
    TargetedPackBoosterEngine? boosterEngine,
    AutoFormatSelector? formatSelector,
    PackQualityGatekeeperService? gatekeeper,
    LearningPathStore? store,
    AssessmentPackSynthesizer? synthesizer,
    AutogenStatusDashboardService? dashboard,
  }) : boosterEngine = boosterEngine ?? TargetedPackBoosterEngine(),
       formatSelector = formatSelector ?? AutoFormatSelector(),
       gatekeeper = gatekeeper ?? const PackQualityGatekeeperService(),
       store = store ?? const LearningPathStore(),
       synthesizer = synthesizer ?? const AssessmentPackSynthesizer(),
       dashboard = dashboard ?? AutogenStatusDashboardService.instance;

  TrainingPackModel _toModel(TrainingPackTemplateV2 t) => TrainingPackModel(
    id: t.id,
    title: t.name,
    spots: t.spots,
    tags: t.tags,
    metadata: t.meta,
  );

  Future<List<InjectedPathModule>> execute({
    required String userId,
    required AdaptivePlan plan,
    required int budgetMinutes,
    required String sig,
    String? abArm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final boosterPerSpot =
        prefs.getDouble('planner.minsPerSpot.booster') ?? 0.6;
    final assessPerSpot =
        prefs.getDouble('planner.minsPerSpot.assessment') ?? 0.5;
    final dedupDays = prefs.getInt('planner.moduleIdDaysDedup') ?? 14;
    final padding = prefs.getInt('planner.budgetPaddingMins') ?? 5;
    final budget = max(0, budgetMinutes - padding);

    final existing = await store.listModules(userId);
    final cutoff = DateTime.now().subtract(Duration(days: dedupDays));

    final modules = <InjectedPathModule>[];
    var used = 0;

    var index = 0;
    for (final c in plan.clusters) {
      var boosters = await boosterEngine.generateClusterBoosterPacks(
        clusters: [c],
      );
      boosters = boosters
          .where((b) => gatekeeper.isQualityAcceptable(_toModel(b)))
          .toList();
      if (boosters.isEmpty) continue;

      final fmt = formatSelector.effectiveFormat();
      final assess = await synthesizer.createAssessment(
        tags: c.tags,
        size: max(1, (fmt.spotsPerPack / 2).round()),
        clusterId: c.clusterId,
        themeName: c.themeName,
      );
      if (!gatekeeper.isQualityAcceptable(_toModel(assess))) {
        continue;
      }

      final assessMins = (assess.spotCount * assessPerSpot).ceil();
      final boosterInfos = <_PackInfo>[];
      for (final b in boosters) {
        final mins = (b.spotCount * boosterPerSpot).ceil();
        final ev = b.tags.fold<double>(
          0,
          (prev, t) => prev + (plan.tagWeights[t] ?? 0.0),
        );
        boosterInfos.add(_PackInfo(b, mins, ev));
      }
      boosterInfos.sort((a, b) {
        final cmp = a.ev.compareTo(b.ev);
        if (cmp != 0) return cmp;
        return a.template.id.compareTo(b.template.id);
      });
      var boosterMins = boosterInfos.fold<int>(0, (s, b) => s + b.mins);
      var moduleMins = boosterMins + assessMins;
      while (boosterInfos.isNotEmpty && used + moduleMins > budget) {
        final removed = boosterInfos.removeAt(0);
        boosterMins -= removed.mins;
        moduleMins -= removed.mins;
      }
      if (used + moduleMins > budget) continue;

      final boosterIds = [for (final b in boosterInfos) b.template.id];
      final sortedIds = [...boosterIds]..sort();
      final assessmentId = assess.id;
      final duplicate = existing.any((m) {
        if (m.createdAt.isBefore(cutoff)) return false;
        if (m.clusterId != c.clusterId) return false;
        if (m.assessmentPackId != assessmentId) return false;
        final ids = [...m.boosterPackIds]..sort();
        return const ListEquality().equals(ids, sortedIds);
      });
      if (duplicate) continue;

      final hashInput = [...c.tags, ...sortedIds, assessmentId].join('|');
      final planHash = sha1.convert(utf8.encode(hashInput)).toString();
      final plannerScore = c.tags.fold<double>(
        0,
        (s, t) => s + (plan.tagWeights[t] ?? 0.0),
      );
      final module = InjectedPathModule(
        moduleId: 'm_${sig.substring(0, 10)}_$index',
        clusterId: c.clusterId,
        themeName: c.themeName,
        theoryIds: const [],
        boosterPackIds: boosterIds,
        assessmentPackId: assessmentId,
        createdAt: DateTime.now(),
        triggerReason: 'adaptivePlan',
        metrics: {
          'clusterTags': c.tags,
          'planHash': planHash,
          'plannerScore': plannerScore,
          if (abArm != null && abArm.isNotEmpty) 'abArm': abArm,
        },
        itemsDurations: {
          'theoryMins': 0,
          'boosterMins': boosterMins,
          'assessmentMins': assessMins,
        },
      );
      await store.upsertModule(userId, module);
      modules.add(module);
      used += moduleMins;
      index++;
    }

    dashboard.update(
      'AdaptiveExecutor',
      AutogenStatus(
        isRunning: false,
        currentStage: jsonEncode({
          'clusters': plan.clusters.length,
          'modulesCreated': modules.length,
          'budgetUsed': used,
        }),
      ),
    );

    return modules;
  }
}
