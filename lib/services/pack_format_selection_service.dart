import 'dart:math';

import 'training_run_ab_comparator_service.dart';

/// Selects the best performing variant for a pack using A/B comparison
/// metrics.
class PackFormatSelectionService {
  final TrainingRunABComparatorService comparator;

  PackFormatSelectionService({required this.comparator});

  /// Returns the identifier of the best variant for [packId] from
  /// [variantIds] based on metrics priority: accuracy, retention, and
  /// earlyDrop (lower is better).
  ///
  /// If all variants have fewer than 3 samples, returns `null`.
  String? selectBestVariant({
    required String packId,
    required List<String> variantIds,
  }) {
    if (variantIds.isEmpty) return null;

    // Determine sample sizes for each variant.
    final repo = comparator.repository;
    final sampleSizes = <String, int>{
      for (final v in variantIds)
        v: repo.getLogs(packId: packId, variant: v).length,
    };

    // Fallback: if no variant has at least 3 samples, do not select.
    if (sampleSizes.values.every((s) => s < 3)) {
      return null;
    }

    // Pairwise comparisons to accumulate wins for each variant.
    final scores = {for (final v in variantIds) v: 0};
    for (var i = 0; i < variantIds.length; i++) {
      for (var j = i + 1; j < variantIds.length; j++) {
        final a = variantIds[i];
        final b = variantIds[j];
        final result = comparator.compare(
          packIdA: packId,
          packIdB: packId,
          variantA: a,
          variantB: b,
        );
        final winner = _winner(result, a, b);
        if (winner != null) {
          scores[winner] = scores[winner]! + 1;
        }
      }
    }

    final maxScore = scores.values.reduce(max);
    final best = scores.entries
        .where((e) => e.value == maxScore)
        .map((e) => e.key)
        .toList();
    return best.length == 1 ? best.first : null;
  }

  String? _winner(ABComparisonResult r, String a, String b) {
    if (r.accuracyA != r.accuracyB) {
      return r.accuracyA > r.accuracyB ? a : b;
    }
    if (r.retentionA != r.retentionB) {
      return r.retentionA > r.retentionB ? a : b;
    }
    if (r.earlyDropA != r.earlyDropB) {
      return r.earlyDropA < r.earlyDropB ? a : b;
    }
    return null;
  }
}
