import 'dart:async';
import 'dart:math';

import '../models/action_evaluation_request.dart';

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
}
