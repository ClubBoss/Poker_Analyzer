import 'package:flutter/foundation.dart';

import '../models/training_pack_model.dart';
import 'pack_quality_score_calculator_service.dart';
import '../core/models/spot_seed/seed_issue.dart';

/// Filters out training packs that do not meet the minimum quality score.
class PackQualityGatekeeperService {
  const PackQualityGatekeeperService({
    PackQualityScoreCalculatorService? scoreCalculator,
  }) : _scoreCalculator = scoreCalculator ?? const PackQualityScoreCalculatorService();

  final PackQualityScoreCalculatorService _scoreCalculator;

  /// Returns true if the [pack]'s quality score meets or exceeds [minScore].
  ///
  /// If the pack does not already have a `qualityScore` stored in its
  /// metadata, it is calculated and cached before evaluation.
  bool isQualityAcceptable(TrainingPackModel pack,
      {double minScore = 0.7,
      Map<String, List<SeedIssue>> seedIssues = const {}}) {
    var score = pack.metadata['qualityScore'] as double?;
    if (score == null) {
      score = _scoreCalculator.calculateQualityScore(pack);
    }
    if (score < minScore) {
      debugPrint(
          'PackQualityGatekeeperService: rejected pack ${pack.id} with score ${score.toStringAsFixed(2)} < threshold $minScore');
      return false;
    }
    final issues = seedIssues[pack.id] ?? const <SeedIssue>[];
    if (issues.any((i) => i.severity == 'error')) {
      debugPrint(
          'PackQualityGatekeeperService: rejected pack ${pack.id} due to seed validation errors');
      return false;
    }
    return true;
  }
}

