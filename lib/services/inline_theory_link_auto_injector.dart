import 'dart:math';

import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_pack_model.dart';
import '../models/autogen_status.dart';
import 'autogen_status_dashboard_service.dart';
import 'autogen_stats_dashboard_service.dart';

/// Summary of a single injection run.
class InlineTheoryInjectionResult {
  final int linkedCount;
  final int rejectedLowScore;
  final double avgScore;
  final int uniqueTheoryBlocks;

  const InlineTheoryInjectionResult({
    required this.linkedCount,
    required this.rejectedLowScore,
    required this.avgScore,
    required this.uniqueTheoryBlocks,
  });

  Map<String, dynamic> toJson() => {
        'linkedCount': linkedCount,
        'avgScore': avgScore,
        'uniqueTheoryBlocks': uniqueTheoryBlocks,
        'rejectedLowScore': rejectedLowScore,
      };
}

/// Injects references to [InlineTheoryEntry] into [TrainingPackSpot]s based on
/// a weighted scoring of tags, board texture, and cluster proximity.
class InlineTheoryLinkAutoInjector {
  final bool enabled;
  final int maxLinksPerSpot;
  final double minScore;
  final double wTag;
  final double wTex;
  final double wCluster;
  final bool preferNovelty;

  const InlineTheoryLinkAutoInjector({
    this.enabled = true,
    this.maxLinksPerSpot = 2,
    this.minScore = 0.5,
    this.wTag = 0.6,
    this.wTex = 0.25,
    this.wCluster = 0.15,
    this.preferNovelty = true,
  });

  /// Attaches theory links to all spots within [model] using [theoryIndex].
  /// Returns summary statistics of the operation.
  InlineTheoryInjectionResult injectLinks(
    TrainingPackModel model,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'InlineTheoryLinkAutoInjector',
      const AutogenStatus(isRunning: true, currentStage: 'inject', progress: 0),
    );
    try {
      final result = _injectAll(model.spots, theoryIndex, status);
      if (result.linkedCount > 0) {
        print(
          'InlineTheoryLinkAutoInjector: injected '
          '${result.linkedCount} links',
        );
      }
      status.update(
        'InlineTheoryLinkAutoInjector',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return result;
    } catch (e) {
      status.update(
        'InlineTheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// Convenience method to inject links into a list of [spots].
  InlineTheoryInjectionResult injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'InlineTheoryLinkAutoInjector',
      const AutogenStatus(isRunning: true, currentStage: 'inject', progress: 0),
    );
    try {
      final result = _injectAll(spots, theoryIndex, status);
      if (result.linkedCount > 0) {
        print(
          'InlineTheoryLinkAutoInjector: injected '
          '${result.linkedCount} links',
        );
      }
      status.update(
        'InlineTheoryLinkAutoInjector',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return result;
    } catch (e) {
      status.update(
        'InlineTheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }

  InlineTheoryInjectionResult _injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
    AutogenStatusDashboardService status,
  ) {
    if (!enabled) {
      return const InlineTheoryInjectionResult(
        linkedCount: 0,
        rejectedLowScore: 0,
        avgScore: 0,
        uniqueTheoryBlocks: 0,
      );
    }
    final dashboard = AutogenStatsDashboardService.instance;
    final used = <String>{};
    var linked = 0;
    var rejected = 0;
    var scoreSum = 0.0;

    for (var i = 0; i < spots.length; i++) {
      final spot = spots[i];
      spot.inlineTheory = null;
      spot.meta.remove('theoryLinks');

      final candidates = <({InlineTheoryEntry entry, double score})>[];
      for (final e in theoryIndex.values) {
        final s = _score(spot, e);
        if (s >= minScore) {
          candidates.add((entry: e, score: s));
        }
      }
      if (candidates.isEmpty) {
        rejected++;
        continue;
      }
      candidates.sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        if (preferNovelty) {
          final aUsed = used.contains(a.entry.id ?? a.entry.tag);
          final bUsed = used.contains(b.entry.id ?? b.entry.tag);
          if (aUsed != bUsed) return aUsed ? 1 : -1;
        }
        return 0;
      });

      final selected = candidates.take(maxLinksPerSpot).toList();
      final links = <Map<String, dynamic>>[];
      for (final c in selected) {
        final id = c.entry.id ?? c.entry.tag;
        used.add(id);
        links.add({
          'id': id,
          'title': c.entry.title,
          'score': double.parse(c.score.toStringAsFixed(2)),
        });
        scoreSum += c.score;
        linked++;
      }
      spot.meta['theoryLinks'] = links;
      if (links.isNotEmpty) {
        spot.inlineTheory = selected.first.entry;
      }
      status.update(
        'InlineTheoryLinkAutoInjector',
        AutogenStatus(
          isRunning: true,
          currentStage: 'inject',
          progress: (i + 1) / spots.length,
        ),
      );
    }
    if (linked > 0) {
      dashboard.recordTheoryLinking(
        linked: linked,
        rejectedLowScore: rejected,
        ids: used,
        avgScore: scoreSum / linked,
      );
    }
    return InlineTheoryInjectionResult(
      linkedCount: linked,
      rejectedLowScore: rejected,
      avgScore: linked > 0 ? scoreSum / linked : 0,
      uniqueTheoryBlocks: used.length,
    );
  }

  double _score(TrainingPackSpot spot, InlineTheoryEntry entry) {
    final spotTags = spot.tags.toSet();
    final theoryTags = entry.allTags.toSet();
    final union = spotTags.union(theoryTags);
    final jaccard = union.isEmpty
        ? 0.0
        : spotTags.intersection(theoryTags).length / union.length;

    double textureMatch = 0;
    final spotTextures = (spot.meta['boardTextureTags'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};
    if (entry.textureBuckets.isNotEmpty && spotTextures.isNotEmpty) {
      if (spotTextures.any(entry.textureBuckets.contains)) {
        textureMatch = 1;
      }
    }

    double clusterSim = 0;
    final spotClusters = <String>{};
    final sc = spot.meta['clusterIds'] ?? spot.meta['clusterId'];
    if (sc is List) {
      spotClusters.addAll(sc.map((e) => e.toString()));
    } else if (sc is String) {
      spotClusters.add(sc);
    }
    if (spotClusters.isNotEmpty && entry.clusterIds.isNotEmpty) {
      final intersection =
          spotClusters.intersection(entry.clusterIds.toSet()).length.toDouble();
      clusterSim =
          intersection / sqrt(spotClusters.length * entry.clusterIds.length);
    }

    return wTag * jaccard + wTex * textureMatch + wCluster * clusterSim;
  }
}
