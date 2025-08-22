import 'dart:math' as math;

import '../models/training_pack_model.dart';
import 'spot_fingerprint_generator.dart';

class PackQualityScoreCalculatorService {
  PackQualityScoreCalculatorService({
    SpotFingerprintGenerator? fingerprint,
  }) : _fingerprint = fingerprint ?? const SpotFingerprintGenerator();

  final SpotFingerprintGenerator _fingerprint;

  double calculateQualityScore(TrainingPackModel pack) {
    final tags = <String>[];
    final boards = <String>{};
    var theoryCount = 0;
    final seen = <String>{};
    var duplicates = 0;

    for (final spot in pack.spots) {
      tags.addAll(spot.tags);
      if (spot.board.isNotEmpty) {
        boards.add(spot.board.join());
      }
      if (spot.theoryRefs.isNotEmpty) theoryCount++;
      final fp = _fingerprint.generate(spot);
      if (!seen.add(fp)) duplicates++;
    }

    final totalTags = tags.length;
    final uniqueTags = tags.toSet().length;
    final tagDiversityScore = totalTags == 0 ? 0.0 : uniqueTags / totalTags;

    final boardDiversityScore = pack.spots.isEmpty
        ? 0.0
        : boards.length / pack.spots.length;

    double balanceScore = 0.0;
    if (uniqueTags > 0) {
      final counts = <String, int>{};
      for (final t in tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
      final mean = totalTags / uniqueTags;
      var variance = 0.0;
      for (final c in counts.values) {
        variance += math.pow(c - mean, 2) as double;
      }
      variance /= uniqueTags;
      final sd = math.sqrt(variance);
      final cv = mean == 0 ? 0.0 : sd / mean;
      balanceScore = 1 / (1 + cv);
    }

    final theoryRatio = pack.spots.isEmpty
        ? 0.0
        : theoryCount / pack.spots.length;
    final hasTheoryLinks = theoryRatio >= 0.7 ? 1.0 : theoryRatio / 0.7;

    final deduplicationScore = pack.spots.isEmpty
        ? 1.0
        : 1 - duplicates / pack.spots.length;

    final score =
        (tagDiversityScore +
            boardDiversityScore +
            balanceScore +
            hasTheoryLinks +
            deduplicationScore) /
        5.0;

    pack.metadata['qualityScore'] = score;
    return score;
  }
}
