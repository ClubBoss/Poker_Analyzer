import "mistake_tag.dart";
import "training_spot_attempt.dart";

class MistakeInsight {
  final MistakeTag tag;
  final int count;
  final double evLoss;
  final String shortExplanation;
  final List<TrainingSpotAttempt> examples;

  const MistakeInsight({
    required this.tag,
    required this.count,
    required this.evLoss,
    required this.shortExplanation,
    required this.examples,
  });
}
