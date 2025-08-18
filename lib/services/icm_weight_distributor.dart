import '../models/v2/training_pack_spot.dart';

/// Assigns a normalized weight to each [TrainingPackSpot].
///
/// Spots with rarer tags or types receive higher weights. An optional [icmMap]
/// can override weights for specific spot IDs or tags. The resulting weights are
/// stored in `spot.meta['weight']` and normalized so that the sum equals `1.0`.
class ICMWeightDistributor {
  /// Distributes weights across [spots].
  void distribute(List<TrainingPackSpot> spots, {Map<String, double>? icmMap}) {
    if (spots.isEmpty) return;

    final Map<String, int> tagCounts = <String, int>{};
    final Map<String, int> typeCounts = <String, int>{};

    for (final spot in spots) {
      typeCounts[spot.type] = (typeCounts[spot.type] ?? 0) + 1;
      for (final String tag in spot.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final Map<TrainingPackSpot, double> rawWeights =
        <TrainingPackSpot, double>{};

    for (final spot in spots) {
      double weight = 0;

      // Frequency-based component
      if (spot.tags.isNotEmpty) {
        for (final tag in spot.tags) {
          final int count = tagCounts[tag] ?? 1;
          weight += 1 / count;
        }
      }
      final int typeCount = typeCounts[spot.type] ?? 1;
      weight += 1 / typeCount;

      // External ICM map overrides
      if (icmMap != null) {
        if (icmMap.containsKey(spot.id)) {
          weight = icmMap[spot.id]!;
        } else {
          for (final tag in spot.tags) {
            if (icmMap.containsKey(tag)) {
              weight = icmMap[tag]!;
              break;
            }
          }
        }
      }

      rawWeights[spot] = weight;
    }

    final double total = rawWeights.values.fold(
      0,
      (double a, double b) => a + b,
    );
    if (total == 0) {
      final double equal = 1 / spots.length;
      for (final spot in spots) {
        spot.meta['weight'] = equal;
      }
      return;
    }

    rawWeights.forEach((spot, weight) {
      spot.meta['weight'] = weight / total;
    });
  }
}
