import '../jam_fold_evaluator.dart';

/// Facade over [JamFoldEvaluator] to compute jam/fold EV for a single spot.
class JamFoldModel {
  final JamFoldEvaluator _evaluator;

  JamFoldModel({Map<String, double>? weights})
      : _evaluator =
            weights != null ? JamFoldEvaluator.fromWeights(weights) : JamFoldEvaluator();

  /// Evaluates a spot described by [board] and [spr].
  ///
  /// Returns a map containing `decision`, `jamEV` and `foldEV`.
  /// If [explain] is true, extra metadata is included under `explain`.
  Map<String, dynamic> evaluate({
    required FlopBoard board,
    required double spr,
    Map<String, double>? priors,
    bool explain = false,
  }) {
    final outcome = _evaluator.evaluate(
      board: board,
      spr: spr,
      priors: priors,
    );
    final result = {
      'decision': outcome.decision,
      'jamEV': outcome.jamEV,
      'foldEV': outcome.foldEV,
    };
    if (explain) {
      result['explain'] = {
        'sprBucket': outcome.sprBucket,
        'tags': outcome.tagsUsed,
        'contrib': outcome.contrib,
      };
    }
    return result;
  }
}
