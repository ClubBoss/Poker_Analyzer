import '../models/action_evaluation_request.dart';
import 'evaluation_executor_service.dart';
import 'service_registry.dart';
import 'evaluation_queue_service.dart';

/// Handles retry operations for evaluation requests.
class RetryEvaluationService {
  final EvaluationExecutor _executor;

  RetryEvaluationService({
    required ServiceRegistry registry,
    EvaluationExecutor? executor,
  }) : _executor = executor ?? registry.get<EvaluationExecutor>();

  /// Attempts to execute an evaluation until it succeeds or [maxAttempts] is
  /// reached. The [req]'s `attempts` field will be updated on each failure.
  Future<bool> processEvaluation(
    ActionEvaluationRequest req, {
    int maxAttempts = 3,
    Duration retryDelay = const Duration(milliseconds: 200),
  }) async {
    var success = false;
    while (!success && req.attempts < maxAttempts) {
      try {
        await _executor.execute(req);
        success = true;
      } catch (_) {
        req.attempts++;
        if (req.attempts < maxAttempts) {
          await Future.delayed(retryDelay);
        }
      }
    }
    return success;
  }

  /// Moves all failed evaluations back to the pending queue and resets their
  /// attempt counters.
  Future<void> retryFailedEvaluations(EvaluationQueueService manager) async {
    if (manager.failed.isEmpty) return;
    for (final r in manager.failed) {
      r.attempts = 0;
    }
    manager.pending.insertAll(0, manager.failed);
    manager.failed.clear();
    await manager.persist();
  }
}
