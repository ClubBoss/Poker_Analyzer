import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/training_spot.dart';
import '../models/evaluation_result.dart';
import 'evaluation_executor_service.dart';

class TrainingSessionController {
  TrainingSessionController({EvaluationExecutorService? executor})
      : _executor = executor ?? EvaluationExecutorService();

  final EvaluationExecutorService _executor;

  Future<EvaluationResult> evaluateSpot(
    BuildContext context,
    TrainingSpot spot,
    String userAction, {
    int attempts = 3,
  }) async {
    var tryCount = 0;
    while (true) {
      try {
        return _executor.evaluate(context, spot, userAction);
      } catch (_) {
        if (++tryCount >= attempts) rethrow;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
