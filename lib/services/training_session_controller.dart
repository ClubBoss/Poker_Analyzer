import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/training_spot.dart';
import '../models/evaluation_result.dart';
import '../models/v2/training_pack_template.dart';
import 'evaluation_executor_service.dart';
import 'service_registry.dart';

class TrainingSessionController {
  TrainingSessionController({
    required ServiceRegistry registry,
    this.packId = 'default',
    this.template,
    EvaluationExecutor? executor,
  }) : _executor = executor ?? registry.get<EvaluationExecutor>();

  final EvaluationExecutor _executor;
  final String packId;
  final TrainingPackTemplate? template;
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
