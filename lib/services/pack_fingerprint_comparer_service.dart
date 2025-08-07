import 'dart:math';

import '../models/action_entry.dart';
import '../models/training_pack_model.dart';

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

/// Internal fingerprint representation used for similarity comparisons.
class _PackFingerprint {
  final Set<String> tags;
  final Set<String> boards;
  final Set<String> actions;
  final Map<int, int> streetCounts;

  const _PackFingerprint({
    required this.tags,
    required this.boards,
    required this.actions,
    required this.streetCounts,
  });
}

/// Compares training packs based on tags, board coverage, action sequences and
/// high level structure.
class PackFingerprintComparerService {
  const PackFingerprintComparerService();

  /// Returns a similarity score between [a] and [b] from 0.0 (no overlap) to
  /// 1.0 (identical) based on weighted metrics.
  double computeSimilarity(TrainingPackModel a, TrainingPackModel b) {
    final fa = _fingerprint(a);
    final fb = _fingerprint(b);

    final tagScore = _jaccard(fa.tags, fb.tags);
    final boardScore = _jaccard(fa.boards, fb.boards);
    final actionScore = _jaccard(fa.actions, fb.actions);
    final structureScore = _structureScore(fa.streetCounts, fb.streetCounts);

    return tagScore * 0.3 +
        boardScore * 0.3 +
        actionScore * 0.3 +
        structureScore * 0.1;
  }

  /// Finds packs from [all] that are similar to [target] above [threshold].
  List<SimilarPackMatch> findSimilarPacks(
    TrainingPackModel target,
    List<TrainingPackModel> all, {
    double threshold = 0.8,
  }) {
    final matches = <SimilarPackMatch>[];
    for (final p in all) {
      if (identical(p, target) || p.id == target.id) continue;
      final sim = computeSimilarity(target, p);
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
        final sim = computeSimilarity(a, b);
        if (sim >= threshold) {
          results.add(PackSimilarityResult(a: a, b: b, similarity: sim));
        }
      }
    }
    return results;
  }

  _PackFingerprint _fingerprint(TrainingPackModel pack) {
    final tags = <String>{
      for (final t in pack.tags) t.trim().toLowerCase(),
    };
    final boards = <String>{};
    final actions = <String>{};
    final streetCounts = <int, int>{};

    for (final spot in pack.spots) {
      tags.addAll(spot.tags.map((t) => t.trim().toLowerCase()));

      if (spot.board.isNotEmpty) {
        boards.add(spot.board.join());
      }

      streetCounts[spot.street] = (streetCounts[spot.street] ?? 0) + 1;

      final entries = spot.hand.actions.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final line = <String>[];
      for (final kv in entries) {
        for (final a in kv.value) {
          line.add(a.action);
        }
      }
      if (line.isNotEmpty) actions.add(line.join('-'));
    }

    return _PackFingerprint(
      tags: tags,
      boards: boards,
      actions: actions,
      streetCounts: streetCounts,
    );
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final inter = a.intersection(b).length.toDouble();
    final union = a.union(b).length.toDouble();
    return union == 0 ? 0.0 : inter / union;
  }

  double _structureScore(Map<int, int> a, Map<int, int> b) {
    final streets = {...a.keys, ...b.keys};
    if (streets.isEmpty) return 1.0;
    var minSum = 0;
    var maxSum = 0;
    for (final s in streets) {
      final av = a[s] ?? 0;
      final bv = b[s] ?? 0;
      minSum += min(av, bv);
      maxSum += max(av, bv);
    }
    if (maxSum == 0) return 0.0;
    return minSum / maxSum;
  }
}

