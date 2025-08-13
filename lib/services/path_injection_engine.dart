import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/injected_path_module.dart';
import 'auto_skill_gap_clusterer.dart';
import 'inline_pack_theory_clusterer.dart';
import 'targeted_pack_booster_engine.dart';
import 'path_registry.dart';
import 'pack_novelty_guard_service.dart';
import 'autogen_status_dashboard_service.dart';
import 'learning_path_store.dart';
import 'assessment_pack_synthesizer.dart';
import 'learning_path_events.dart';

class PathInjectionDecision {
  final bool shouldInject;
  final String reason;
  const PathInjectionDecision(this.shouldInject, this.reason);
}

/// Engine that injects theory, boosters and assessments for skill clusters
/// directly into the user learning path.
class PathInjectionEngine {
  final InlinePackTheoryClusterer theoryClusterer;
  final TargetedPackBoosterEngine boosterEngine;
  final PackNoveltyGuardService noveltyGuard;
  final AutogenStatusDashboardService dashboard;
  final PathRegistry registry;
  final LearningPathStore store;
  final AssessmentPackSynthesizer synthesizer;

  PathInjectionEngine({
    InlinePackTheoryClusterer? theoryClusterer,
    TargetedPackBoosterEngine? boosterEngine,
    PackNoveltyGuardService? noveltyGuard,
    AutogenStatusDashboardService? dashboard,
    PathRegistry? registry,
    LearningPathStore? store,
    AssessmentPackSynthesizer? synthesizer,
  })  : theoryClusterer = theoryClusterer ?? InlinePackTheoryClusterer(),
        boosterEngine = boosterEngine ?? TargetedPackBoosterEngine(),
        noveltyGuard = noveltyGuard ?? const PackNoveltyGuardService(),
        dashboard = dashboard ?? AutogenStatusDashboardService.instance,
        registry = registry ?? const PathRegistry(),
        store = store ?? const LearningPathStore(),
        synthesizer = synthesizer ?? const AssessmentPackSynthesizer();

  Future<List<InjectedPathModule>> injectForClusters({
    required List<SkillTagCluster> clusters,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('path.inject.enabled') ?? true)) return [];
    if (!(prefs.getBool('path.store.enabled') ?? true)) return [];
    final modules = <InjectedPathModule>[];
    final skips = <String, int>{};
    final assessmentSize = prefs.getInt('path.inject.assessmentSize') ?? 6;
    final theoryMins = prefs.getInt('path.inject.theoryMins') ?? 5;
    final boosterMins = prefs.getInt('path.inject.boosterMins') ?? 10;
    final assessmentMins = prefs.getInt('path.inject.assessmentMins') ?? 5;
    for (final c in clusters) {
      final decision = await evaluateOpportunity(c, userId);
      if (!decision.shouldInject) {
        skips.update(decision.reason, (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      final theoryIds = c.tags.take(2).map((t) => 'theory_$t').toList();
      final boosters =
          await boosterEngine.generateClusterBoosterPacks(clusters: [c]);
      final boosterIds = boosters.map((b) => b.id).toList();
      final assessment = await synthesizer.createAssessment(
        tags: c.tags,
        size: assessmentSize,
        clusterId: c.clusterId,
        themeName: c.themeName,
      );
      final assessmentId = assessment.id;
      final allIds = [...theoryIds, ...boosterIds, assessmentId];
      if (!noveltyGuard.isNovel(c.tags.toSet(), allIds)) {
        skips.update('novelty', (v) => v + 1, ifAbsent: () => 1);
        continue;
      }
      final moduleId = _moduleId(userId, c.clusterId);
      final module = InjectedPathModule(
        moduleId: moduleId,
        clusterId: c.clusterId,
        themeName: c.themeName,
        theoryIds: theoryIds,
        boosterPackIds: boosterIds,
        assessmentPackId: assessmentId,
        createdAt: DateTime.now(),
        triggerReason: 'autoCluster',
        metrics: {
          'clusterTags': c.tags,
        },
        itemsDurations: {
          'theoryMins': theoryMins,
          'boosterMins': boosterMins,
          'assessmentMins': assessmentMins,
        },
      );
      modules.add(module);
      await registry.record(userId, c.tags);
      await store.upsertModule(userId, module);
      LearningPathEvents.moduleInjected(userId, module);
      dashboard.recordPathModuleInjected();
    }
    dashboard.update(
      'PathInjectionEngine',
      AutogenStatus(
        isRunning: false,
        currentStage: jsonEncode({
          'pathModulesInjected': modules.length,
          'skips': skips,
        }),
        progress: 1.0,
      ),
    );
    return modules;
  }

  Future<PathInjectionDecision> evaluateOpportunity(
      SkillTagCluster c, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final recentHours = prefs.getInt('path.inject.recentHours') ?? 72;
    final maxPerWeek = prefs.getInt('path.inject.maxPerWeek') ?? 3;
    final maxActive = prefs.getInt('path.inject.maxActive') ?? 2;
    final recent = Duration(hours: recentHours);
    final hash = PathRegistry.hashTags(c.tags);
    if (await registry.hasRecent(userId, hash, recent)) {
      return const PathInjectionDecision(false, 'recent_duplicate');
    }
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekCount = await registry.countSince(userId, weekAgo);
    if (weekCount >= maxPerWeek) {
      return const PathInjectionDecision(false, 'cadence_limit');
    }
    final activeCount = await registry.countSince(userId, weekAgo);
    if (activeCount >= maxActive) {
      return const PathInjectionDecision(false, 'cadence_limit');
    }
    return const PathInjectionDecision(true, 'ok');
  }

  /// Deterministic module id derived from user, cluster and week of year.
  String _moduleId(String userId, String clusterId) {
    final now = DateTime.now();
    final week = _weekOfYear(now);
    final input = '$userId|$clusterId|$week';
    return md5.convert(utf8.encode(input)).toString();
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDay);
    return (diff.inDays / 7).floor();
  }

  Future<void> removeModule(String moduleId) async {
    // Placeholder for rollback support.
  }

  Future<void> onModuleStarted(String userId, String moduleId) async {
    await store.updateModuleStatus(userId, moduleId, 'in_progress');
    LearningPathEvents.moduleStarted(userId, moduleId);
    dashboard.recordPathModuleStarted();
  }

  Future<void> onModuleCompleted(String userId, String moduleId,
      {required double passRate}) async {
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getDouble('path.module.completeThreshold') ?? 0.7;
    final status = passRate >= threshold ? 'completed' : 'in_progress';
    await store.updateModuleStatus(userId, moduleId, status,
        passRate: passRate);
    if (status == 'completed') {
      LearningPathEvents.moduleCompleted(userId, moduleId, passRate);
      dashboard.recordPathModuleCompleted(passRate);
    }
  }
}
