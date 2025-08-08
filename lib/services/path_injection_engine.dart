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

  PathInjectionEngine({
    InlinePackTheoryClusterer? theoryClusterer,
    TargetedPackBoosterEngine? boosterEngine,
    PackNoveltyGuardService? noveltyGuard,
    AutogenStatusDashboardService? dashboard,
    PathRegistry? registry,
  })  : theoryClusterer = theoryClusterer ?? InlinePackTheoryClusterer(),
        boosterEngine = boosterEngine ?? TargetedPackBoosterEngine(),
        noveltyGuard = noveltyGuard ?? const PackNoveltyGuardService(),
        dashboard = dashboard ?? AutogenStatusDashboardService.instance,
        registry = registry ?? const PathRegistry();

  Future<List<InjectedPathModule>> injectForClusters({
    required List<SkillTagCluster> clusters,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('path.inject.enabled') ?? true)) return [];
    final modules = <InjectedPathModule>[];
    final skips = <String, int>{};
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
      final assessmentId = 'assessment_${c.clusterId}';
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
      );
      modules.add(module);
      await registry.record(userId, c.tags);
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
}
