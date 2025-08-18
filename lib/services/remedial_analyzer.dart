import '../models/training_spot_attempt.dart';
import '../models/remedial_spec.dart';
import '../models/v2/training_pack_spot.dart';
import 'board_texture_classifier.dart';

class RemedialAnalyzer {
  final BoardTextureClassifier _classifier;

  RemedialAnalyzer({BoardTextureClassifier? classifier})
    : _classifier = classifier ?? const BoardTextureClassifier();

  RemedialSpec analyze(
    Iterable<TrainingSpotAttempt> attempts, {
    double targetAccuracy = 0.0,
  }) {
    final tagMisses = <String, int>{};
    final textureMisses = <String, int>{};
    final streetMisses = <int, int>{};
    var total = 0;
    var correct = 0;

    for (final a in attempts) {
      total++;
      if (a.userAction == a.correctAction) {
        correct++;
        continue;
      }
      for (final t in a.spot.tags) {
        tagMisses[t] = (tagMisses[t] ?? 0) + 1;
      }
      final boardCards = a.spot.hand.boardCardsForStreet(a.spot.street);
      final textures = _classifier.classify(boardCards.take(3).join());
      for (final tex in textures) {
        textureMisses[tex] = (textureMisses[tex] ?? 0) + 1;
      }
      streetMisses[a.spot.street] = (streetMisses[a.spot.street] ?? 0) + 1;
    }

    final accuracy = total == 0 ? 1.0 : correct / total;
    final topTags = tagMisses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTagKeys = [for (final e in topTags.take(3)) e.key];

    final spec = RemedialSpec(
      topTags: topTagKeys,
      textureCounts: textureMisses,
      streetBias: streetMisses.isEmpty
          ? 0
          : streetMisses.entries
                .reduce((a, b) => a.value >= b.value ? a : b)
                .key,
      minAccuracyTarget: targetAccuracy > 0 ? targetAccuracy : accuracy,
    );

    return spec;
  }
}
