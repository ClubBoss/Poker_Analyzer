import '../models/mistake_tag.dart';
import '../models/training_spot_attempt.dart';
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

  /// Returns theory tags relevant to a mistake.
  ///
  /// The rules are intentionally simplistic and cover only a few common
  /// scenarios to bootstrap mistake‑driven lesson suggestions.
  ///
  /// * Folding when the correct action is push with significant EV loss will
  ///   return `['pushRange', 'overfold']`.
  /// * Folding instead of calling returns `['callRange']` with an additional
  ///   `overfold` tag for large EV losses.
  /// * Calling when the correct action is fold returns `['callRange']`.
  /// * Aggressive actions (bet/push/raise) when a fold is correct yield
  ///   `['overbluff']`.
  /// * Checking when betting is correct maps to `cbet` on the flop and `probe`
  ///   on later streets.
  List<String> classifyTheory(TrainingSpotAttempt attempt) {
    final tags = <String>{};
    final user = attempt.userAction.toLowerCase();
    final correct = attempt.correctAction.toLowerCase();
    final evDiff = attempt.evDiff;

    if (user == 'fold' && correct == 'push') {
      tags.add('pushRange');
      if (evDiff <= -2) tags.add('overfold');
    } else if (user == 'fold' && correct == 'call') {
      tags.add('callRange');
      if (evDiff <= -2) tags.add('overfold');
    } else if (user == 'call' && correct == 'fold') {
      tags.add('callRange');
    } else if ((user == 'bet' || user == 'push' || user == 'raise') &&
        correct == 'fold') {
      tags.add('overbluff');
    } else if (user == 'check' && (correct == 'bet' || correct == 'push')) {
      final street = attempt.spot.street;
      final villain = attempt.spot.villainAction?.toLowerCase() ?? '';
      if (street == 1 && villain == 'check') {
        tags.add('cbet');
      } else {
        tags.add('probe');
      }
    }

    return tags.toList();
  }
}
