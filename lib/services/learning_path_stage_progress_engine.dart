import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import 'session_log_service.dart';

class LearningPathStageProgressEngine {
  final SessionLogService logs;

  LearningPathStageProgressEngine({required this.logs});

  Map<String, int> _handsByPack = {};
  DateTime _lastComputed = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _loading;

  Future<void> _ensureData() async {
    if (_loading != null) {
      await _loading;
      return;
    }
    if (_handsByPack.isNotEmpty &&
        DateTime.now().difference(_lastComputed) < const Duration(minutes: 5)) {
      return;
    }
    final future = _compute();
    _loading = future;
    await future;
    _loading = null;
  }

  Future<void> _compute() async {
    await logs.load();
    final map = <String, int>{};
    for (final l in logs.logs) {
      final count = l.correctCount + l.mistakeCount;
      map.update(l.templateId, (v) => v + count, ifAbsent: () => count);
    }
    _handsByPack = map;
    _lastComputed = DateTime.now();
  }

  Future<Map<String, double>> getStageProgress(
    LearningPathTemplateV2 template,
  ) async {
    await _ensureData();
    final result = <String, double>{};
    for (final stage in template.stages) {
      result[stage.packId] = _progressForStage(stage);
    }
    return result;
  }

  double _progressForStage(LearningPathStageModel stage) {
    final hands = _handsByPack[stage.packId] ?? 0;
    if (stage.minHands <= 0) return 0.0;
    final ratio = hands / stage.minHands;
    return ratio.clamp(0.0, 1.0);
  }
}
