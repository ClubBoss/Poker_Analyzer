import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import 'learning_path_registry_service.dart';
import 'session_log_service.dart';

class TrainingPathProgressServiceV2 {
  final SessionLogService logs;
  final LearningPathRegistryService registry;

  TrainingPathProgressServiceV2({
    required this.logs,
    LearningPathRegistryService? registry,
  }) : registry = registry ?? LearningPathRegistryService.instance;

  String? _pathId;
  LearningPathTemplateV2? _template;
  final Map<String, _StageProgress> _progress = {};
  final Set<String> _unlocked = {};

  Future<void> loadProgress(String pathId) async {
    final templates = await registry.loadAll();
    _template = templates.firstWhereOrNull((e) => e.id == pathId);
    if (_template == null) return;
    _pathId = pathId;
    final prefs = await SharedPreferences.getInstance();
    _progress.clear();
    for (final stage in _template!.stages) {
      final acc = prefs.getDouble(_accKey(stage.id)) ?? 0.0;
      final hands = prefs.getInt(_handsKey(stage.id)) ?? 0;
      _progress[stage.id] = _StageProgress(accuracy: acc, hands: hands);
    }
    _recomputeUnlocked();
  }

  Future<void> markStageCompleted(String stageId, double accuracy) async {
    if (_pathId == null || _template == null) return;
    final prefs = await SharedPreferences.getInstance();
    final stage = _template!.stages.firstWhereOrNull((s) => s.id == stageId);
    if (stage == null) return;
    final stats = _computeStats(stage);
    final acc = accuracy.isNaN ? stats.accuracy : accuracy;
    final prog = _StageProgress(accuracy: acc, hands: stats.hands);
    _progress[stageId] = prog;
    await prefs.setDouble(_accKey(stageId), prog.accuracy);
    await prefs.setInt(_handsKey(stageId), prog.hands);
    _recomputeUnlocked();
  }

  bool isStageUnlocked(String stageId) => _unlocked.contains(stageId);

  double getStageAccuracy(String stageId) =>
      _progress[stageId]?.accuracy ?? 0.0;

  int getStageHands(String stageId) => _progress[stageId]?.hands ?? 0;

  /// Returns `true` if the given [stageId] meets hands and accuracy targets.
  bool getStageCompletion(String stageId) {
    final stage = _template?.stages.firstWhereOrNull((s) => s.id == stageId);
    if (stage == null) return false;
    final prog = _progress[stageId];
    if (prog == null) return false;
    return prog.hands >= stage.minHands &&
        prog.accuracy >= stage.requiredAccuracy;
  }

  List<String> unlockedStageIds() => List.unmodifiable(_unlocked);

  // --- internal helpers ---

  String _prefix(String stageId) =>
      'training_path_v2_${_pathId ?? ''}_$stageId';
  String _accKey(String stageId) => '${_prefix(stageId)}_acc';
  String _handsKey(String stageId) => '${_prefix(stageId)}_hands';

  _StageProgress _computeStats(LearningPathStageModel stage) {
    var hands = 0;
    var correct = 0;
    if (stage.subStages.isEmpty) {
      for (final log in logs.logs) {
        if (log.templateId == stage.packId) {
          hands += log.correctCount + log.mistakeCount;
          correct += log.correctCount;
        }
      }
    } else {
      for (final sub in stage.subStages) {
        for (final log in logs.logs) {
          if (log.templateId == sub.packId) {
            hands += log.correctCount + log.mistakeCount;
            correct += log.correctCount;
          }
        }
      }
    }
    final acc = hands == 0 ? 0.0 : correct / hands * 100;
    return _StageProgress(accuracy: acc, hands: hands);
  }

  void _recomputeUnlocked() {
    _unlocked.clear();
    if (_template == null) return;

    final prereq = <String, Set<String>>{};
    for (final s in _template!.stages) {
      for (final u in s.unlocks) {
        prereq.putIfAbsent(u, () => <String>{}).add(s.id);
      }
    }

    final completed = <String>{};
    final queue = <String>[for (final s in _template!.entryStages) s.id];

    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (_unlocked.contains(id)) continue;
      _unlocked.add(id);
      final stage = _template!.stages.firstWhere((e) => e.id == id);
      final prog = _progress[id];
      bool done = false;
      if (prog != null) {
        if (stage.subStages.isEmpty) {
          done = prog.hands >= stage.minHands &&
              prog.accuracy >= stage.requiredAccuracy;
        } else {
          done = true;
          for (final sub in stage.subStages) {
            final stats = _computeStats(LearningPathStageModel(
              id: '',
              title: '',
              description: '',
              packId: sub.packId,
              requiredAccuracy: sub.requiredAccuracy,
              minHands: sub.minHands,
            ));
            if (stats.hands < sub.minHands ||
                stats.accuracy < sub.requiredAccuracy) {
              done = false;
              break;
            }
          }
        }
      }
      if (done) {
        completed.add(id);
        for (final next in stage.unlocks) {
          final deps = prereq[next] ?? const <String>{};
          if (deps.every(completed.contains)) {
            queue.add(next);
          }
        }
      }
    }
  }
}

class _StageProgress {
  double accuracy;
  int hands;
  _StageProgress({this.accuracy = 0.0, this.hands = 0});
}
