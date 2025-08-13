import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'booster_pack_validator_service.dart';
import 'booster_anomaly_detector.dart';

class BoosterTestReport {
  final int totalSpots;
  final double evAvg;
  final int emptyExplanations;
  final List<String> issues;
  final Map<String, int> tagHistogram;
  final String quality;

  const BoosterTestReport({
    required this.totalSpots,
    required this.evAvg,
    required this.emptyExplanations,
    required this.issues,
    required this.tagHistogram,
    required this.quality,
  });
}

class BoosterQuickTesterEngine {
  const BoosterQuickTesterEngine();

  BoosterTestReport test(TrainingPackTemplateV2 pack,
      {bool detectAnomalies = false}) {
    final validation = const BoosterPackValidatorService().validate(pack);
    final total = pack.spots.length;
    int emptyExp = 0;
    int badPos = 0;
    final ids = <String>{};
    final duplicates = <String>[];
    double evSum = 0.0;
    int evCount = 0;
    final tags = <String, int>{};

    for (final s in pack.spots) {
      if ((s.explanation ?? '').trim().isEmpty) emptyExp++;
      if (s.hand.position == HeroPosition.unknown) badPos++;
      if (!ids.add(s.id)) duplicates.add(s.id);
      final ev = s.heroEv;
      if (ev != null) {
        evSum += ev;
        evCount++;
      }
      for (final t in s.tags) {
        final tag = t.trim();
        if (tag.isEmpty) continue;
        tags[tag] = (tags[tag] ?? 0) + 1;
      }
    }

    final evAvg = evCount > 0 ? evSum / evCount : 0.0;

    final issues = <String>[...validation.errors, ...validation.warnings];
    if (duplicates.isNotEmpty) issues.add('duplicate_ids');
    if (detectAnomalies) {
      final anomaly = const BoosterAnomalyDetector().analyze([pack]);
      if (anomaly.duplicatedHands.isNotEmpty) {
        issues.add('dup_hands:${anomaly.duplicatedHands.length}');
      }
      if (anomaly.repeatedBoards.isNotEmpty) {
        issues.add('dup_boards:${anomaly.repeatedBoards.length}');
      }
      if (anomaly.evOutliers.isNotEmpty) {
        issues.add('ev_outliers:${anomaly.evOutliers.join(',')}');
      }
      if (anomaly.weakExplanations.isNotEmpty) {
        issues.add('weak_expl:${anomaly.weakExplanations.length}');
      }
    }
    final emptyPct = total > 0 ? emptyExp / total : 0.0;
    final badPct = total > 0 ? badPos / total : 0.0;
    final quality = validation.isValid
        ? _quality(emptyPct, badPct, duplicates.isNotEmpty)
        : 'fail';

    issues.add('empty_expl: ${(emptyPct * 100).toStringAsFixed(1)}%');
    issues.add('bad_pos: ${(badPct * 100).toStringAsFixed(1)}%');

    return BoosterTestReport(
      totalSpots: total,
      evAvg: evAvg,
      emptyExplanations: emptyExp,
      issues: issues,
      tagHistogram: tags,
      quality: quality,
    );
  }

  String _quality(double emptyPct, double badPct, bool hasDupes) {
    if (hasDupes || emptyPct > 0.5 || badPct > 0.5) return 'fail';
    if (emptyPct > 0.1 || badPct > 0.1) return 'warning';
    return 'pass';
  }
}
