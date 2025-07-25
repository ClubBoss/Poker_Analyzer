import '../models/mistake_tag.dart';
import '../models/training_spot_attempt.dart';
import '../models/mistake.dart';
import 'mistake_categorization_engine.dart';
import 'auto_mistake_tagger_engine.dart';

class MistakeTagClassification {
  final MistakeTag tag;
  final double severity;
  const MistakeTagClassification({required this.tag, required this.severity});
}

/// Simple classifier for major mistakes.
class MistakeTagClassifier {
  const MistakeTagClassifier();

  /// Returns [MistakeTagClassification] if the attempt can be tagged.
  MistakeTagClassification? classify(TrainingSpotAttempt attempt) {
    final tags = const AutoMistakeTaggerEngine().tag(attempt);
    if (tags.isEmpty) return null;
    final tag = tags.first;

    // Estimate severity based on hand strength and EV difference.
    const engine = MistakeCategorizationEngine();
    final strength = engine.computeHandStrength(attempt.spot.hand.heroCards);
    final diff = attempt.evDiff.abs().clamp(0, 5);
    final severity = ((strength * 0.7) + (diff / 5 * 0.3))
        .clamp(0, 1)
        .toDouble();

    return MistakeTagClassification(tag: tag, severity: severity);
  }
}
