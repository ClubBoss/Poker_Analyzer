import 'package:collection/collection.dart';

import 'skill_loss_detector.dart';

class MistakeCluster {
  final String tag;
  final int count;

  MistakeCluster({required this.tag, required this.count});
}

class RecoveryPath {
  final String tag;
  final double urgencyScore;
  final String reason;

  RecoveryPath({
    required this.tag,
    required this.urgencyScore,
    required this.reason,
  });
}

class ReviewPathRecommender {
  ReviewPathRecommender();

  List<RecoveryPath> suggestRecoveryPath({
    required List<SkillLoss> losses,
    required List<MistakeCluster> mistakeClusters,
    required Map<String, double> goalMissRatesByTag,
  }) {
    final tags = <String>{
      ...losses.map((e) => e.tag),
      ...mistakeClusters.map((e) => e.tag),
      ...goalMissRatesByTag.keys,
    };

    final List<RecoveryPath> results = [];

    for (final tag in tags) {
      double score = 0;
      final reasons = <String>[];

      final loss = losses.firstWhereOrNull((l) => l.tag == tag);
      if (loss != null && loss.drop > 0.15) {
        score += 1.0;
        reasons.add('skill drop');
      }

      final cluster = mistakeClusters.firstWhereOrNull((c) => c.tag == tag);
      if (cluster != null && cluster.count >= 3) {
        score += 0.8;
        reasons.add('many mistakes');
      }

      final missRate = goalMissRatesByTag[tag];
      if (missRate != null && missRate > 0.4) {
        score += 0.5;
        reasons.add('missed goals');
      }

      if (score > 0) {
        results.add(
          RecoveryPath(
            tag: tag,
            urgencyScore: score,
            reason: reasons.join(', '),
          ),
        );
      }
    }

    results.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
    return results;
  }
}
