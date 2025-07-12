import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/training_spot.dart';
import '../models/evaluation_result.dart';
import 'evaluation_executor_service.dart';
import 'service_registry.dart';

class TrainingSessionController {
  TrainingSessionController({
    required ServiceRegistry registry,
    EvaluationExecutor? executor,
  }) : _executor = executor ?? registry.get<EvaluationExecutor>();

  final EvaluationExecutor _executor;
  TrainingSpot? _currentSpot;

  TrainingSpot? get currentSpot => _currentSpot;

  void replaySpot(TrainingSpot spot) {
    _currentSpot = spot;
  }

  Future<EvaluationResult> evaluateSpot(
    BuildContext context,
    TrainingSpot spot,
    String userAction, {
    int attempts = 3,
  }) async {
    var tryCount = 0;
    while (true) {
      try {
        return _executor.evaluateSpot(context, spot, userAction);
      } catch (_) {
        if (++tryCount >= attempts) rethrow;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
