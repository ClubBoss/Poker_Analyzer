import 'dart:math';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'booster_similarity_engine.dart';

class BoosterPackSimilarityReport {
  final int similarSpotCount;
  final double similarityPercent;

  const BoosterPackSimilarityReport({
    this.similarSpotCount = 0,
    this.similarityPercent = 0,
  });
}

class BoosterPackSimilarityReporter {
  final BoosterSimilarityEngine _engine;
  final double _threshold;

  const BoosterPackSimilarityReporter({
    BoosterSimilarityEngine? engine,
    double threshold = 0.85,
  })  : _engine = engine ?? const BoosterSimilarityEngine(),
        _threshold = threshold;

  BoosterPackSimilarityReport computeSimilarity(
    TrainingPackTemplateV2 a,
    TrainingPackTemplateV2 b, {
    double? threshold,
  }) {
    final thr = threshold ?? _threshold;
    if (a.spots.isEmpty || b.spots.isEmpty) {
      return const BoosterPackSimilarityReport();
    }

    final usedB = <int>{};
    var count = 0;
    for (final spotA in a.spots) {
      double best = 0;
      int bestIdx = -1;
      for (var i = 0; i < b.spots.length; i++) {
        if (usedB.contains(i)) continue;
        final sim = _similarity(spotA, b.spots[i]);
        if (sim > best) {
          best = sim;
          bestIdx = i;
        }
      }
      if (bestIdx != -1 && best >= thr) {
        usedB.add(bestIdx);
        count++;
      }
    }

    final maxLen = max(a.spots.length, b.spots.length);
    final percent = maxLen == 0 ? 0 : count / maxLen;
    return BoosterPackSimilarityReport(
      similarSpotCount: count,
      similarityPercent: percent,
    );
  }

  double _similarity(TrainingPackSpot a, TrainingPackSpot b) {
    final res = _engine.analyzeSpots([a, b], threshold: -1);
    return res.isNotEmpty ? res.first.similarity : 0.0;
  }
}
