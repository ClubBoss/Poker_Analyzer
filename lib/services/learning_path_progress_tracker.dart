import '../models/learning_path_template_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'learning_path_orchestrator.dart';
import 'pack_library_service.dart';
import 'training_progress_service.dart';

/// Tracks progress across the entire learning path.
class LearningPathProgressTracker {
  final Future<LearningPathTemplateV2> Function() _getPath;
  final Future<double> Function(String) _stageProgress;
  final Future<TrainingPackTemplateV2?> Function(String) _getPack;
  final Future<double> Function(String) _tagProgress;

  LearningPathProgressTracker({
    Future<LearningPathTemplateV2> Function()? getPath,
    Future<double> Function(String stageId)? getStageProgress,
    Future<TrainingPackTemplateV2?> Function(String id)? getPack,
    Future<double> Function(String tag)? getTagProgress,
  })  : _getPath = getPath ?? LearningPathOrchestrator.instance.resolve,
        _stageProgress = getStageProgress ??
            TrainingProgressService.instance.getStageProgress,
        _getPack = getPack ?? PackLibraryService.instance.getById,
        _tagProgress =
            getTagProgress ?? TrainingProgressService.instance.getTagProgress;

  Map<String, double>? _cache;
  DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);
  Map<String, Map<String, double>>? _tagCache;
  DateTime _tagCacheTime = DateTime.fromMillisecondsSinceEpoch(0);

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

  /// Returns progress per tag for each stage.
  Future<Map<String, Map<String, double>>> getTagProgressPerStage() async {
    final now = DateTime.now();
    if (_tagCache != null &&
        now.difference(_tagCacheTime) < const Duration(minutes: 5)) {
      return _tagCache!;
    }

    final path = await _getPath();
    final result = <String, Map<String, double>>{};

    for (final stage in path.stages) {
      final pack = await _getPack(stage.packId);
      if (pack == null) continue;
      final tags = <String>{
        ...pack.tags.map((e) => e.trim().toLowerCase()),
        for (final s in pack.spots)
          ...s.tags.map((e) => e.trim().toLowerCase()),
      }..removeWhere((e) => e.isEmpty);

      final tagMap = <String, double>{};
      for (final tag in tags) {
        final prog = await _tagProgress(tag);
        tagMap[tag] = prog;
      }
      if (tagMap.isNotEmpty) result[stage.id] = tagMap;
    }

    _tagCache = result;
    _tagCacheTime = now;
    return result;
  }
}
