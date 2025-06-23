import 'dart:async';
import 'dart:math';

import '../models/action_evaluation_request.dart';
import '../models/evaluation_result.dart';
import '../models/training_spot.dart';

/// Handles execution of a single evaluation request.
class EvaluationExecutorService {
  /// Executes the evaluation for [req].
  ///
  /// This stub simulates a delay and introduces a random failure
  /// for debugging purposes.
  Future<void> execute(ActionEvaluationRequest req) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (Random().nextDouble() < 0.2) {
      throw Exception('Simulated evaluation failure');
    }
  }

  /// Evaluates [userAction] taken in [spot] and returns an [EvaluationResult].
  ///
  /// The initial implementation simply checks if the action matches the
  /// expected action for the hero at the given training spot.
  EvaluationResult evaluate(TrainingSpot spot, String userAction) {
    final expectedAction = spot.actions[spot.heroIndex].action;
    final correct = userAction == expectedAction;
    final expectedEquity =
        spot.equities != null && spot.equities!.length > spot.heroIndex
            ? spot.equities![spot.heroIndex].clamp(0.0, 1.0)
            : 0.5;
    final userEquity = correct
        ? expectedEquity
        : (expectedEquity - 0.1).clamp(0.0, 1.0);
    return EvaluationResult(
      correct: correct,
      expectedAction: expectedAction,
      userEquity: userEquity,
      expectedEquity: expectedEquity,
      hint: correct ? null : 'Подумай о диапазоне оппонента',
    );
  }
}
