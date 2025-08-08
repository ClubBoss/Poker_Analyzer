import 'dart:math';

import 'package:collection/collection.dart';

import '../models/injected_path_module.dart';
import '../models/training_pack_model.dart';
import 'autogen_status_dashboard_service.dart';
import 'inline_pack_theory_clusterer.dart';
import 'learning_path_store.dart';
import 'mistake_telemetry_store.dart';
import 'theory_library_index.dart';
import 'theory_novelty_registry.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../models/autogen_status.dart';

class TheoryLinkAutoInjector {
  TheoryLinkAutoInjector({
    required this.store,
    required this.libraryIndex,
    required this.telemetry,
    required this.noveltyRegistry,
    InlinePackTheoryClusterer? clusterer,
    AutogenStatusDashboardService? dashboard,
    TrainingPackLibraryV2? packLibrary,
    this.maxPerModule = 3,
    this.maxPerPack = 2,
    this.maxPerSpot = 2,
    this.weightErrorRate = 0.5,
    this.weightTagMatch = 0.5,
    this.noveltyRecent = const Duration(hours: 72),
    this.noveltyMinOverlap = 0.6,
  })  : clusterer =
            clusterer ?? InlinePackTheoryClusterer(maxPerPack: maxPerPack, maxPerSpot: maxPerSpot),
        dashboard = dashboard ?? AutogenStatusDashboardService.instance,
        packLibrary = packLibrary ?? TrainingPackLibraryV2.instance;

  final LearningPathStore store;
  final TheoryLibraryIndex libraryIndex;
  final MistakeTelemetryStore telemetry;
  final TheoryNoveltyRegistry noveltyRegistry;
  final InlinePackTheoryClusterer clusterer;
  final AutogenStatusDashboardService dashboard;
  final TrainingPackLibraryV2 packLibrary;
  final int maxPerModule;
  final int maxPerPack;
  final int maxPerSpot;
  final double weightErrorRate;
  final double weightTagMatch;
  final Duration noveltyRecent;
  final double noveltyMinOverlap;

  Future<int> injectForUser(String userId) async {
    final modules = await store.listModules(userId);
    final pending = modules.where((m) => m.status == 'pending' || m.status == 'in_progress');
    if (pending.isEmpty) return 0;
    final library = await libraryIndex.all();
    final errorRates = await telemetry.getErrorRates();
    var injected = 0;

    for (final module in pending) {
      final demand = <String>{};
      final clusterTags = (module.metrics['clusterTags'] as List?)?.cast<String>();
      if (clusterTags != null && clusterTags.isNotEmpty) {
        demand.addAll(clusterTags.map((e) => e.toLowerCase()));
      } else {
        for (final id in [...module.boosterPackIds, module.assessmentPackId]) {
          final tpl = packLibrary.getById(id);
          if (tpl != null) {
            demand.addAll(tpl.tags.map((e) => e.toLowerCase()));
          }
        }
      }
      if (demand.isEmpty) continue;

      final candidates = <_Scored>[];
      for (final res in library) {
        final j = _jaccard(res.tags, demand);
        if (j == 0) continue;
        var err = 0.0;
        for (final t in res.tags) {
          err = max(err, errorRates[t] ?? 0);
        }
        final score = weightTagMatch * j + weightErrorRate * err;
        candidates.add(_Scored(res, score));
      }
      if (candidates.isEmpty) continue;
      candidates.sort((a, b) => b.score.compareTo(a.score));

      final uncovered = Set<String>.from(demand);
      final selected = <_Scored>[];
      final remaining = List<_Scored>.from(candidates);
      while (selected.length < maxPerModule && uncovered.isNotEmpty && remaining.isNotEmpty) {
        remaining.sort((a, b) {
          final gainA = a.resource.tags.where(uncovered.contains).length;
          final gainB = b.resource.tags.where(uncovered.contains).length;
          if (gainA != gainB) return gainB.compareTo(gainA);
          return b.score.compareTo(a.score);
        });
        final best = remaining.removeAt(0);
        final gain = best.resource.tags.where(uncovered.contains).length;
        if (gain == 0 && selected.isNotEmpty) break;
        selected.add(best);
        uncovered.removeAll(best.resource.tags);
      }
      if (selected.isEmpty) continue;
      final theoryIds = selected.map((e) => e.resource.id).toList();

      if (await noveltyRegistry.isRecentDuplicate(userId, demand.toList(), theoryIds,
          within: noveltyRecent, minOverlap: noveltyMinOverlap)) {
        if (candidates.length > selected.length) {
          final weakest = selected.reduce((a, b) => a.score <= b.score ? a : b);
          final replacement = candidates.firstWhere(
              (c) => !theoryIds.contains(c.resource.id) && c.resource.id != weakest.resource.id,
              orElse: () => weakest);
          if (replacement != weakest) {
            final idx = selected.indexOf(weakest);
            selected[idx] = replacement;
          }
        }
        final swappedIds = selected.map((e) => e.resource.id).toList();
        if (await noveltyRegistry.isRecentDuplicate(userId, demand.toList(), swappedIds,
            within: noveltyRecent, minOverlap: noveltyMinOverlap)) {
          dashboard.update(
            'TheoryLinkAutoInjector',
            AutogenStatus(isRunning: false, currentStage: 'novelty-skip:${module.moduleId}', progress: 1.0),
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
        final clusters = (attached.metadata['theoryClusters'] as List?)?.length ?? 0;
        clustersCount += clusters;
        for (final s in attached.spots) {
          final links = (s.meta['theoryLinks'] as List?)?.length ?? 0;
          linksCount += links;
        }
      }
      dashboard.recordTheoryInjection(clusters: clustersCount, links: linksCount);
    }
    return injected;
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
