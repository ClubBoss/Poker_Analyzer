import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/learning_path_player_progress.dart';
import '../services/learning_path_loader.dart';
import '../services/learning_path_player_progress_service.dart';
import '../services/learning_path_telemetry.dart';

/// Controller that manages an active learning path session. It keeps track of
/// progress and exposes the currently unlocked stage.
class LearningPathController extends ChangeNotifier {
  LearningPathController({
    LearningPathLoader? loader,
    LearningPathProgressService? progressService,
    LearningPathTelemetry? telemetry,
  })  : _loader = loader ?? const LearningPathLoader(),
        _progressService =
            progressService ?? LearningPathProgressService.instance,
        _telemetry = telemetry ?? const LearningPathTelemetry();

  final LearningPathLoader _loader;
  final LearningPathProgressService _progressService;
  final LearningPathTelemetry _telemetry;

  LearningPathTemplateV2? _path;
  LearningPathProgress _progress = LearningPathProgress();
  String? _pathId;
  DateTime? _lastRecord;

  LearningPathTemplateV2? get path => _path;
  String? get currentStageId => _progress.currentStageId;
  LearningPathStageModel? get currentStage =>
      _path?.stages.firstWhere(
          (s) => s.id == _progress.currentStageId,
          orElse: () => _path!.stages.first);

  StageProgress stageProgress(String stageId) =>
      _progress.stages[stageId] ?? const StageProgress();

  bool isStageUnlocked(String stageId) {
    final stage = _path?.stages.firstWhere(
      (s) => s.id == stageId,
      orElse: () => throw Exception('Stage not found: ' + stageId),
    );
    if (stage == null) return false;
    if (stage.unlockAfter.isEmpty) {
      // unlocked if all previous stages are completed
      final index = _path!.stages.indexOf(stage);
      for (var i = 0; i < index; i++) {
        final id = _path!.stages[i].id;
        if (!(_progress.stages[id]?.completed ?? false)) return false;
      }
      return true;
    }
    return stage.unlockAfter
        .every((id) => _progress.stages[id]?.completed ?? false);
  }

  Future<void> load(String pathId) async {
    _pathId = pathId;
    _path = await _loader.load(pathId);
    _progress = await _progressService.load(pathId);
    _progress = _progress.copyWith(
      currentStageId: _progress.currentStageId ?? _path!.entryStages.first.id,
    );
    await _progressService.save(pathId, _progress);
    notifyListeners();
  }

  void recordHand({required bool correct}) {
    final stageId = _progress.currentStageId;
    if (stageId == null) return;
    final now = DateTime.now();
    if (_lastRecord != null &&
        now.difference(_lastRecord!).inMilliseconds < 100) {
      return;
    }
    _lastRecord = now;
    final stage =
        _path!.stages.firstWhere((s) => s.id == stageId, orElse: () => _path!.stages.first);
    final current = stageProgress(stageId).recordHand(correct: correct);
    var updated = current;
    if (current.handsPlayed >= stage.requiredHands &&
        current.accuracy >= stage.requiredAccuracy) {
      updated = current.copyWith(
        completed: true,
        completedAt: DateTime.now(),
      );
      _unlockNext(stageId);
      final id = _pathId;
      if (id != null) {
        _telemetry.logStageComplete(
            pathId: id, stageId: stageId, progress: updated);
      }
    }
    _progress = _progress.copyWith(
      stages: {
        ..._progress.stages,
        stageId: updated,
      },
    );
    _persist();
    notifyListeners();
  }

  void _unlockNext(String completedId) {
    final completedIds = <String>{};
    _progress.stages.forEach((id, s) {
      if (id == completedId || s.completed) completedIds.add(id);
    });
    // try unlock by explicit dependencies first
    for (final stage in _path!.stages) {
      if (_progress.stages[stage.id]?.completed == true) continue;
      if (stage.unlockAfter.isNotEmpty &&
          stage.unlockAfter.every(completedIds.contains)) {
        _progress = _progress.copyWith(currentStageId: stage.id);
        return;
      }
    }
    // otherwise pick next sequential stage
    final index = _path!.stages.indexWhere((s) => s.id == completedId);
    for (var i = index + 1; i < _path!.stages.length; i++) {
      final stage = _path!.stages[i];
      if (_progress.stages[stage.id]?.completed == true) continue;
      if (isStageUnlocked(stage.id)) {
        _progress = _progress.copyWith(currentStageId: stage.id);
        return;
      }
    }
    // all done
    _progress = _progress.copyWith(currentStageId: null);
  }

  Future<void> _persist() async {
    final id = _pathId;
    if (id != null) {
      await _progressService.save(id, _progress);
    }
  }

  @override
  void dispose() {
    final id = _pathId;
    if (id != null) {
      _telemetry.logSummary(pathId: id, progress: _progress);
    }
    super.dispose();
  }

  Future<void> reset() async {
    final id = _pathId;
    if (id == null) return;
    await _progressService.reset(id);
    _progress = LearningPathProgress();
    await load(id);
  }
}

