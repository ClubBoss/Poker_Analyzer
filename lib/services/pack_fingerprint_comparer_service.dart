import 'dart:math';

import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../utils/app_logger.dart';
import 'spot_fingerprint_generator.dart';

/// Represents another pack that is similar to the target.
class SimilarPackMatch {
  final TrainingPackModel pack;
  final double similarity;

  const SimilarPackMatch(this.pack, this.similarity);
}

/// Represents a pair of packs with a similarity score.
class PackSimilarityResult {
  final TrainingPackModel a;
  final TrainingPackModel b;
  final double similarity;

  const PackSimilarityResult({
    required this.a,
    required this.b,
    required this.similarity,
  });
}

/// Compares training packs based on spot fingerprints and metadata overlap.
class PackFingerprintComparerService {
  final SpotFingerprintGenerator _fingerprint;
  final bool _debug;

  const PackFingerprintComparerService({
    SpotFingerprintGenerator? fingerprint,
    bool debug = false,
  })  : _fingerprint = fingerprint ?? const SpotFingerprintGenerator(),
        _debug = debug;

  /// Returns a similarity score between [a] and [b] from 0.0 (no overlap) to
  /// 1.0 (identical) based on weighted heuristics.
  double compare(TrainingPackModel a, TrainingPackModel b) {
    final spotA = {for (final s in a.spots) _fingerprint.generate(s)};
    final spotB = {for (final s in b.spots) _fingerprint.generate(s)};
    final tagsA = _collectTags(a);
    final tagsB = _collectTags(b);
    final clustersA = _collectClusters(a);
    final clustersB = _collectClusters(b);

    final spotScore = _jaccard(spotA, spotB);
    final tagScore = _jaccard(tagsA, tagsB);
    final clusterScore = _jaccard(clustersA, clustersB);
    final templateScore = _templateScore(a, b);
    final countScore = _countScore(a, b);

    final result = spotScore * 0.5 +
        tagScore * 0.2 +
        clusterScore * 0.1 +
        templateScore * 0.1 +
        countScore * 0.1;

    if (_debug) {
      AppLogger.log(
        'PackFingerprintComparerService: ${a.id} vs ${b.id} -> '
        'spots=$spotScore tags=$tagScore clusters=$clusterScore '
        'template=$templateScore count=$countScore => $result',
      );
    }

    return result;
  }

  /// Returns `true` when the similarity between [a] and [b] meets [threshold].
  bool areSimilar(TrainingPackModel a, TrainingPackModel b,
          {double threshold = 0.9}) =>
      compare(a, b) >= threshold;

  /// Finds packs from [all] that are similar to [target] above [threshold].
  List<SimilarPackMatch> findSimilarPacks(
    TrainingPackModel target,
    List<TrainingPackModel> all, {
    double threshold = 0.8,
  }) {
    final matches = <SimilarPackMatch>[];
    for (final p in all) {
      if (identical(p, target) || p.id == target.id) continue;
      final sim = compare(target, p);
      if (sim >= threshold) {
        matches.add(SimilarPackMatch(p, sim));
      }
    }
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    return matches;
  }

  /// Finds all pairs of packs in [packs] that have similarity above
  /// [threshold]. Each pair is only reported once.
  List<PackSimilarityResult> findDuplicates(
    List<TrainingPackModel> packs, {
    double threshold = 0.8,
  }) {
    final results = <PackSimilarityResult>[];
    for (var i = 0; i < packs.length; i++) {
      for (var j = i + 1; j < packs.length; j++) {
        final a = packs[i];
        final b = packs[j];
        final sim = compare(a, b);
        if (sim >= threshold) {
          results.add(PackSimilarityResult(a: a, b: b, similarity: sim));
        }
      }
    }
    return results;
  }

  Set<String> _collectTags(TrainingPackModel pack) {
    final result = <String>{for (final t in pack.tags) _norm(t)};
    for (final TrainingPackSpot s in pack.spots) {
      result.addAll(s.tags.map(_norm));
    }
    result.removeWhere((e) => e.isEmpty);
    return result;
  }

  Set<String> _collectClusters(TrainingPackModel pack) {
    final result = <String>{};
    for (final TrainingPackSpot s in pack.spots) {
      final meta = s.meta;
      final c = meta['cluster'] ??
          meta['theoryCluster'] ??
          meta['clusterId'] ??
          meta['theoryClusterId'];
      if (c is String && c.trim().isNotEmpty) {
        result.add(c.trim().toLowerCase());
      }
    }
    return result;
  }

  double _templateScore(TrainingPackModel a, TrainingPackModel b) {
    final ta = a.metadata['templateId']?.toString();
    final tb = b.metadata['templateId']?.toString();
    if (ta == null || tb == null) return 0.0;
    return ta == tb ? 1.0 : 0.0;
  }

  double _countScore(TrainingPackModel a, TrainingPackModel b) {
    final aCount = a.spots.length;
    final bCount = b.spots.length;
    if (aCount == 0 && bCount == 0) return 1.0;
    final minCount = min(aCount, bCount);
    final maxCount = max(aCount, bCount);
    if (maxCount == 0) return 0.0;
    return minCount / maxCount;
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final inter = a.intersection(b).length.toDouble();
    final union = a.union(b).length.toDouble();
    return union == 0 ? 0.0 : inter / union;
  }

  String _norm(String v) => v.trim().toLowerCase();
}

