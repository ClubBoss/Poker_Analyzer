import 'learning_path_orchestrator.dart';
import 'training_progress_service.dart';
import 'session_storage_service.dart';

/// Computes which learning path stages should be presented in the weekly planner.
class LearningPathPlannerEngine {
  LearningPathPlannerEngine._();

  static final LearningPathPlannerEngine instance =
      LearningPathPlannerEngine._();

  List<String>? _cache;
  DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns up to seven stage ids that are not yet completed.
  Future<List<String>> getPlannedStageIds() async {
    final now = DateTime.now();
    if (_cache != null &&
        now.difference(_cacheTime) < const Duration(minutes: 5)) {
      return _cache!;
    }

    final path = await LearningPathOrchestrator.instance.resolve();
    final result = <String>[];
    for (final stage in path.stages) {
      if (result.length >= 7) break;
      final progress =
          await TrainingProgressService.instance.getStageProgress(stage.id);
      if (progress < 1.0) {
        result.add(stage.id);
      }
    }

    _cache = result;
    _cacheTime = now;
    return result;
  }

  /// Marks [stageId] as completed and updates the planner state.
  Future<void> markStageCompleted(String stageId) async {
    await TrainingProgressService.instance.markCompleted(stageId);
    _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);
    final cached = _cache;
    if (cached != null) {
      cached.remove(stageId);
    }
    await SessionStorageService.instance.remove('planner_remaining');
  }
}
