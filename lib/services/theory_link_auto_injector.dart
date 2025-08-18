import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';

import '../models/injected_path_module.dart';
import '../models/training_pack_model.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'inline_pack_theory_clusterer.dart';
import 'learning_path_store.dart';
import 'mistake_telemetry_store.dart';
import 'theory_library_index.dart';
import 'theory_link_config_service.dart';
import 'theory_link_policy_engine.dart';
import 'theory_novelty_registry.dart';

enum TheoryLinkSaveStrategy { inMemory, overwriteYaml }

class TheoryLinkAutoInjector {
  TheoryLinkAutoInjector({
    required this.store,
    required this.libraryIndex,
    required this.telemetry,
    required this.noveltyRegistry,
    required this.policy,
    TheoryLinkConfigService? config,
    AutogenStatusDashboardService? dashboard,
    TrainingPackLibraryV2? packLibrary,
    DecayTagRetentionTrackerService? retention,
    this.saveStrategy = TheoryLinkSaveStrategy.inMemory,
  }) : config = config ?? TheoryLinkConfigService.instance,
       dashboard = dashboard ?? AutogenStatusDashboardService.instance,
       packLibrary = packLibrary ?? TrainingPackLibraryV2.instance,
       retention = retention ?? const DecayTagRetentionTrackerService(),
       clusterer = InlinePackTheoryClusterer(
         maxPerPack:
             (config ?? TheoryLinkConfigService.instance).value.maxPerPack,
         maxPerSpot:
             (config ?? TheoryLinkConfigService.instance).value.maxPerSpot,
       ) {
    _applyConfig(this.config.value);
    this.config.notifier.addListener(() {
      _applyConfig(this.config.value);
    });
  }

  final LearningPathStore store;
  final TheoryLibraryIndex libraryIndex;
  final MistakeTelemetryStore telemetry;
  final TheoryNoveltyRegistry noveltyRegistry;
  final TheoryLinkPolicyEngine policy;
  final TheoryLinkConfigService config;
  InlinePackTheoryClusterer clusterer;
  final AutogenStatusDashboardService dashboard;
  final TrainingPackLibraryV2 packLibrary;
  final DecayTagRetentionTrackerService retention;
  final TheoryLinkSaveStrategy saveStrategy;
  late int maxPerModule;
  late int maxPerPack;
  late int maxPerSpot;
  late double weightErrorRate;
  late double weightDecay;
  late double weightTagMatch;
  late Duration noveltyRecent;
  late double noveltyMinOverlap;
  final Map<String, bool> _runningUsers = {};

  void _applyConfig(TheoryLinkConfig cfg) {
    maxPerModule = cfg.maxPerModule;
    maxPerPack = cfg.maxPerPack;
    maxPerSpot = cfg.maxPerSpot;
    weightTagMatch = cfg.wTag;
    weightErrorRate = cfg.wErr;
    weightDecay = cfg.wDecay;
    noveltyRecent = cfg.noveltyRecent;
    noveltyMinOverlap = cfg.noveltyMinOverlap;
    clusterer = InlinePackTheoryClusterer(
      maxPerPack: maxPerPack,
      maxPerSpot: maxPerSpot,
    );
  }

  Future<int> injectForUser(String userId) async {
    if (_runningUsers[userId] == true) return 0;
    _runningUsers[userId] = true;
    try {
      if (config.value.ablationEnabled) {
        dashboard.update(
          'TheoryLinkPolicy',
          AutogenStatus(
            isRunning: false,
            currentStage: jsonEncode({'policyBlocks': 0, 'ablation': true}),
            progress: 1.0,
          ),
        );
        return 0;
      }
      var policyBlocks = 0;
      dashboard.update(
        'TheoryLinkPolicy',
        AutogenStatus(
          isRunning: false,
          currentStage: jsonEncode({'policyBlocks': 0, 'ablation': false}),
          progress: 1.0,
        ),
      );

      final modules = await store.listModules(userId);
      final pending = modules.where(
        (m) => m.status == 'pending' || m.status == 'in_progress',
      );
      if (pending.isEmpty) return 0;
      final library = await libraryIndex.all();
      final errorRates = await telemetry.getErrorRates();
      var injected = 0;

      for (final module in pending) {
        final demand = <String>{};
        final clusterTags = (module.metrics['clusterTags'] as List?)
            ?.cast<String>();
        if (clusterTags != null && clusterTags.isNotEmpty) {
          demand.addAll(clusterTags.map((e) => e.toLowerCase()));
        } else {
          if (packLibrary.packs.isEmpty) {
            await packLibrary.loadFromFolder();
          }
          for (final id in [
            ...module.boosterPackIds,
            module.assessmentPackId,
          ]) {
            final tpl = packLibrary.getById(id);
            if (tpl != null) {
              demand.addAll(tpl.tags.map((e) => e.toLowerCase()));
            }
          }
        }
        if (demand.isEmpty) continue;

        if (!await policy.canInject(userId, demand)) {
          policyBlocks++;
          dashboard.update(
            'TheoryLinkPolicy',
            AutogenStatus(
              isRunning: false,
              currentStage: jsonEncode({
                'policyBlocks': policyBlocks,
                'ablation': false,
              }),
              progress: 1.0,
            ),
          );
          continue;
        }

        final decayScores = await _decayScores(demand);

        final candidates = <_Scored>[];
        for (final res in library) {
          final j = _jaccard(res.tags, demand);
          if (j == 0) continue;
          var err = 0.0;
          var dec = 0.0;
          for (final t in res.tags) {
            err = max(err, errorRates[t] ?? 0);
            dec = max(dec, decayScores[t] ?? 0);
          }
          final score =
              weightTagMatch * j + weightErrorRate * err + weightDecay * dec;
          candidates.add(_Scored(res, score));
        }
        if (candidates.isEmpty) continue;
        candidates.sort((a, b) {
          final diff = b.score.compareTo(a.score);
          if (diff != 0) return diff;
          final idDiff = a.resource.id.compareTo(b.resource.id);
          if (idDiff != 0) return idDiff;
          return a.resource.title.compareTo(b.resource.title);
        });

        final uncovered = Set<String>.from(demand);
        final selected = <_Scored>[];
        final remaining = List<_Scored>.from(candidates);
        while (selected.length < maxPerModule &&
            uncovered.isNotEmpty &&
            remaining.isNotEmpty) {
          remaining.sort((a, b) {
            final gainA = a.resource.tags.where(uncovered.contains).length;
            final gainB = b.resource.tags.where(uncovered.contains).length;
            if (gainA != gainB) return gainB.compareTo(gainA);
            final scoreDiff = b.score.compareTo(a.score);
            if (scoreDiff != 0) return scoreDiff;
            final idDiff = a.resource.id.compareTo(b.resource.id);
            if (idDiff != 0) return idDiff;
            return a.resource.title.compareTo(b.resource.title);
          });
          final best = remaining.removeAt(0);
          final gain = best.resource.tags.where(uncovered.contains).length;
          if (gain == 0 && selected.isNotEmpty) break;
          selected.add(best);
          uncovered.removeAll(best.resource.tags);
        }
        if (selected.isEmpty) continue;
        final theoryIds = selected.map((e) => e.resource.id).toList();

        if (await noveltyRegistry.isRecentDuplicate(
          userId,
          demand.toList(),
          theoryIds,
          within: noveltyRecent,
          minOverlap: noveltyMinOverlap,
        )) {
          if (candidates.length > selected.length) {
            final weakest = selected.reduce(
              (a, b) => a.score <= b.score ? a : b,
            );
            final replacement = candidates.firstWhere(
              (c) =>
                  !theoryIds.contains(c.resource.id) &&
                  c.resource.id != weakest.resource.id,
              orElse: () => weakest,
            );
            if (replacement != weakest) {
              final idx = selected.indexOf(weakest);
              selected[idx] = replacement;
            }
          }
          final swappedIds = selected.map((e) => e.resource.id).toList();
          if (await noveltyRegistry.isRecentDuplicate(
            userId,
            demand.toList(),
            swappedIds,
            within: noveltyRecent,
            minOverlap: noveltyMinOverlap,
          )) {
            dashboard.update(
              'TheoryLinkAutoInjector',
              AutogenStatus(
                isRunning: false,
                currentStage: 'novelty-skip:${module.moduleId}',
                progress: 1.0,
              ),
            );
            continue;
          } else {
            theoryIds
              ..clear()
              ..addAll(swappedIds);
          }
        }

        if (ListEquality().equals(module.theoryIds, theoryIds)) {
          continue; // idempotent
        }

        final durations = Map<String, int>.from(module.itemsDurations ?? {});
        durations['theoryMins'] = theoryIds.length * 5;

        final updated = InjectedPathModule(
          moduleId: module.moduleId,
          clusterId: module.clusterId,
          themeName: module.themeName,
          theoryIds: theoryIds,
          boosterPackIds: module.boosterPackIds,
          assessmentPackId: module.assessmentPackId,
          createdAt: module.createdAt,
          triggerReason: module.triggerReason,
          status: module.status,
          metrics: module.metrics,
          itemsDurations: durations,
        );

        await store.upsertModule(userId, updated);
        await noveltyRegistry.record(userId, demand.toList(), theoryIds);
        await policy.onInjected(userId, demand);
        injected++;

        var clustersCount = 0;
        var linksCount = 0;
        for (final pid in [...module.boosterPackIds, module.assessmentPackId]) {
          final tpl = packLibrary.getById(pid);
          if (tpl == null) continue;
          final model = TrainingPackModel(
            id: tpl.id,
            title: tpl.name,
            spots: tpl.spots,
            tags: tpl.tags,
            metadata: Map<String, dynamic>.from(tpl.meta),
          );
          final attached = clusterer.attach(
            model,
            library,
            mistakeTelemetry: errorRates,
          );
          final clusters =
              (attached.metadata['theoryClusters'] as List?)?.length ?? 0;
          clustersCount += clusters;
          for (final s in attached.spots) {
            final links = (s.meta['theoryLinks'] as List?)?.length ?? 0;
            linksCount += links;
          }
        }
        dashboard.recordTheoryInjection(
          clusters: clustersCount,
          links: linksCount,
        );
      }
      return injected;
    } finally {
      _runningUsers.remove(userId);
    }
  }

  Future<Map<String, double>> _decayScores(
    Set<String> tags, {
    int capDays = 30,
  }) async {
    final result = <String, double>{};
    for (final t in tags) {
      final days = await retention.getDecayScore(t);
      result[t] = min(days, capDays) / capDays;
    }
    return result;
  }
}

class _Scored {
  final TheoryResource resource;
  final double score;
  _Scored(this.resource, this.score);
}

double _jaccard(List<String> a, Set<String> b) {
  final setA = a.toSet();
  final inter = setA.intersection(b).length;
  final union = setA.union(b).length;
  if (union == 0) return 0;
  return inter / union;
}
