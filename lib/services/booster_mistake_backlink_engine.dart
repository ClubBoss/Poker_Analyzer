import "../models/theory_cluster_summary.dart";

import '../models/weak_cluster_info.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/booster_backlink.dart';

/// Maps booster packs back to their originating weak theory clusters.
class BoosterMistakeBacklinkEngine {
  BoosterMistakeBacklinkEngine();

  /// Returns a [BoosterBacklink] describing how [booster] relates to [clusters].
  BoosterBacklink link(
    TrainingPackTemplateV2 booster,
    List<WeakClusterInfo> clusters,
  ) {
    TheoryClusterSummary? matched;
    final generated = booster.meta['generatedFromClusterId']?.toString();
    if (generated != null && generated.isNotEmpty) {
      final ids = generated.split(',').map((e) => e.trim()).toSet();
      for (final c in clusters) {
        if (c.cluster.entryPointIds.any(ids.contains)) {
          matched = c.cluster;
          break;
        }
      }
    }

    final Set<String> tags = {
      for (final t in booster.tags) t.trim().toLowerCase(),
    }..removeWhere((t) => t.isEmpty);
    Set<String> matchingTags = {};

    if (matched == null) {
      double best = 0;
      for (final c in clusters) {
        final clusterTags = c.cluster.sharedTags
            .map((t) => t.trim().toLowerCase())
            .where((t) => t.isNotEmpty)
            .toSet();
        final overlap = tags.intersection(clusterTags);
        if (overlap.length > best) {
          best = overlap.length.toDouble();
          matched = c.cluster;
          matchingTags = overlap;
        }
      }
    } else {
      matchingTags = matched.sharedTags
          .map((t) => t.trim().toLowerCase())
          .where((t) => tags.contains(t))
          .toSet();
    }

    final lessons = matched?.entryPointIds ?? const <String>[];

    return BoosterBacklink(
      sourceCluster: matched,
      matchingTags: matchingTags,
      relatedLessonIds: List<String>.from(lessons),
    );
  }
}
