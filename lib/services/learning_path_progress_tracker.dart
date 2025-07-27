import '../models/learning_path_template_v2.dart';
import 'learning_path_orchestrator.dart';
import 'training_progress_service.dart';

/// Tracks progress across the entire learning path.
class LearningPathProgressTracker {
  final Future<LearningPathTemplateV2> Function() _getPath;
  final Future<double> Function(String) _stageProgress;

  LearningPathProgressTracker({
    Future<LearningPathTemplateV2> Function()? getPath,
    Future<double> Function(String stageId)? getStageProgress,
  })  : _getPath = getPath ?? LearningPathOrchestrator.instance.resolve,
        _stageProgress =
            getStageProgress ?? TrainingProgressService.instance.getStageProgress;

  Map<String, double>? _cache;
  DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns map of stage id to completion ratio (0.0 - 1.0).
  Future<Map<String, double>> getStageProgressMap() async {
    final now = DateTime.now();
    if (_cache != null &&
        now.difference(_cacheTime) < const Duration(minutes: 5)) {
      return _cache!;
    }
    final path = await _getPath();
    final result = <String, double>{};
    for (final stage in path.stages) {
      final p = await _stageProgress(stage.id);
      result[stage.id] = p;
    }
    _cache = result;
    _cacheTime = now;
    return result;
  }

  /// Returns average progress across all stages (0.0 - 1.0).
  Future<double> getOverallProgress() async {
    final map = await getStageProgressMap();
    if (map.isEmpty) return 0.0;
    var sum = 0.0;
    for (final v in map.values) {
      sum += v;
    }
    return sum / map.length;
  }
}
