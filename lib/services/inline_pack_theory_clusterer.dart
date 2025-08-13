import 'dart:math';

import '../models/autogen_status.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'autogen_status_dashboard_service.dart';

/// Lightweight representation of a theory resource that can be linked to a
/// training pack or an individual spot.
class TheoryResource {
  final String id;
  final String title;
  final String uri;
  final List<String> tags;

  const TheoryResource({
    required this.id,
    required this.title,
    required this.uri,
    required this.tags,
  });
}

/// Guard to avoid repeatedly linking the same theory cluster to packs with
/// identical tag sets.
class PackNoveltyGuardService {
  const PackNoveltyGuardService();

  /// Returns true if the combination of [tags] and [itemIds] is considered
  /// novel for the current export session.
  bool isNovel(Set<String> tags, List<String> itemIds) => true;
}

class _ScoredResource {
  final TheoryResource resource;
  final double score;

  const _ScoredResource(this.resource, this.score);
}

class _Cluster {
  final String theme;
  final List<_ScoredResource> items;
  final double score;

  const _Cluster(
      {required this.theme, required this.items, required this.score});
}

/// Clusters theory resources and injects references into packs and spots.
class InlinePackTheoryClusterer {
  InlinePackTheoryClusterer({
    this.maxPerPack = 3,
    this.maxPerSpot = 2,
    this.minConfidence = 0.6,
    this.weightDecay = 0.3,
    this.weightErrorRate = 0.5,
    this.weightTagMatch = 0.2,
    AutogenStatusDashboardService? dashboard,
    PackNoveltyGuardService? noveltyGuard,
  })  : _dashboard = dashboard ?? AutogenStatusDashboardService.instance,
        _noveltyGuard = noveltyGuard ?? const PackNoveltyGuardService();

  final int maxPerPack;
  final int maxPerSpot;
  final double minConfidence;
  final double weightDecay; // currently unused
  final double weightErrorRate;
  final double weightTagMatch;
  final AutogenStatusDashboardService _dashboard;
  final PackNoveltyGuardService _noveltyGuard;

  /// Attaches theory clusters and links to the provided [pack]. The [library]
  /// contains all available theory resources. Optional [mistakeTelemetry]
  /// provides error rates per tag.
  TrainingPackModel attach(
    TrainingPackModel pack,
    List<TheoryResource> library, {
    Map<String, double>? mistakeTelemetry,
  }) {
    final tagSet = pack.spots.expand((s) => s.tags).toSet();
    if (tagSet.isEmpty) return pack;

    // Build scored resources per tag.
    final clusters = <_Cluster>[];
    for (final tag in tagSet) {
      final items = <_ScoredResource>[];
      for (final res in library) {
        if (!res.tags.contains(tag)) continue;
        final score = _score(res, [tag], mistakeTelemetry);
        if (score >= minConfidence) {
          items.add(_ScoredResource(res, score));
        }
      }
      if (items.isEmpty) continue;
      items.sort((a, b) => b.score.compareTo(a.score));
      final clusterScore = items.first.score;
      if (!_noveltyGuard
          .isNovel({tag}, items.map((e) => e.resource.id).toList())) {
        continue; // skip non novel clusters
      }
      clusters.add(_Cluster(theme: tag, items: items, score: clusterScore));
    }

    if (clusters.isEmpty) return pack;

    clusters.sort((a, b) => b.score.compareTo(a.score));
    final selected = clusters.take(maxPerPack).toList();

    // Build pack level metadata.
    final packMeta = Map<String, dynamic>.from(pack.metadata);
    packMeta['theoryClusters'] = selected
        .map((c) => {
              'clusterId': c.theme,
              'theme': c.theme,
              'score': c.score,
              'items': c.items
                  .map((i) => {
                        'id': i.resource.id,
                        'title': i.resource.title,
                        'uri': i.resource.uri,
                        'tags': i.resource.tags,
                      })
                  .toList(),
              'rationale': 'matched tag ${c.theme}',
            })
        .toList();

    // Build spot level links.
    final newSpots = <TrainingPackSpot>[];
    var linkCount = 0;
    for (final spot in pack.spots) {
      final spotTags = spot.tags;
      final links = <Map<String, dynamic>>[];
      for (final cluster in selected) {
        if (!spotTags.contains(cluster.theme)) continue;
        for (final item in cluster.items) {
          if (links.length >= maxPerSpot) break;
          if (!item.resource.tags.any(spotTags.contains)) continue;
          links.add({
            'id': item.resource.id,
            'title': item.resource.title,
            'uri': item.resource.uri,
            'reason':
                'matches tags: ${spotTags.where(item.resource.tags.contains).join(',')}',
            'score': item.score,
          });
          linkCount++;
        }
      }
      final meta = Map<String, dynamic>.from(spot.meta);
      if (links.isNotEmpty) meta['theoryLinks'] = links;
      newSpots.add(spot.copyWith(meta: meta));
    }

    _dashboard.update(
      'InlinePackTheoryClusterer',
      AutogenStatus(
        isRunning: false,
        currentStage: 'clusters:${selected.length} links:$linkCount',
        progress: 1.0,
      ),
    );

    return TrainingPackModel(
      id: pack.id,
      title: pack.title,
      spots: newSpots,
      tags: pack.tags,
      metadata: packMeta,
    );
  }

  double _score(
    TheoryResource res,
    List<String> tags,
    Map<String, double>? mistakeTelemetry,
  ) {
    final overlap = res.tags.where(tags.contains).length;
    final tagScore = overlap / max(res.tags.length, 1);
    var err = 0.0;
    if (mistakeTelemetry != null) {
      for (final t in res.tags) {
        err = max(err, mistakeTelemetry[t] ?? 0);
      }
    }
    return weightTagMatch * tagScore + weightErrorRate * err;
  }
}
