import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import 'learning_path_registry_service.dart';
import 'training_path_progress_service_v2.dart';

/// Summary of user's progress in a learning path.
class LearningPathSummary {
  final String id;
  final String title;
  final int completedStages;
  final int totalStages;
  final double percentComplete;
  final int unlockedStageCount;
  final bool isFinished;
  final LearningPathStageModel? nextStageToTrain;

  const LearningPathSummary({
    required this.id,
    required this.title,
    required this.completedStages,
    required this.totalStages,
    required this.percentComplete,
    required this.unlockedStageCount,
    required this.isFinished,
    required this.nextStageToTrain,
  });
}

class LearningPathSummaryCache {
  final TrainingPathProgressServiceV2 progress;
  final LearningPathRegistryService registry;

  LearningPathSummaryCache({
    required this.progress,
    LearningPathRegistryService? registry,
  }) : registry = registry ?? LearningPathRegistryService.instance;

  final List<LearningPathSummary> _summaries = [];
  Future<void>? _refreshing;

  List<LearningPathSummary> get summaries => List.unmodifiable(_summaries);

  LearningPathSummary? summaryById(String id) =>
      _summaries.firstWhereOrNull((e) => e.id == id);

  Future<void> refresh() async {
    if (_refreshing != null) {
      await _refreshing;
      return;
    }
    final future = _compute();
    _refreshing = future;
    await future;
    _refreshing = null;
  }

  Future<void> _compute() async {
    final templates = await registry.loadAll();
    final prefs = await SharedPreferences.getInstance();
    _summaries.clear();
    for (final t in templates) {
      final progressMap = <String, _StageProgress>{};
      for (final s in t.stages) {
        final acc = prefs.getDouble(_accKey(t.id, s.id)) ?? 0.0;
        final hands = prefs.getInt(_handsKey(t.id, s.id)) ?? 0;
        progressMap[s.id] = _StageProgress(accuracy: acc, hands: hands);
      }
      final unlocked = _computeUnlocked(t, progressMap);

      var completed = 0;
      LearningPathStageModel? nextStage;
      for (final s in t.stages) {
        final p = progressMap[s.id];
        final done = p != null &&
            p.hands >= s.minHands &&
            p.accuracy >= s.requiredAccuracy;
        if (done) {
          completed++;
        } else if (nextStage == null && unlocked.contains(s.id)) {
          nextStage = s;
        }
      }

      final percent = t.stages.isEmpty ? 0.0 : completed / t.stages.length;
      _summaries.add(
        LearningPathSummary(
          id: t.id,
          title: t.title,
          completedStages: completed,
          totalStages: t.stages.length,
          percentComplete: percent,
          unlockedStageCount: unlocked.length,
          isFinished: completed >= t.stages.length,
          nextStageToTrain: nextStage,
        ),
      );
    }
  }

  Set<String> _computeUnlocked(
    LearningPathTemplateV2 template,
    Map<String, _StageProgress> progress,
  ) {
    final unlocked = <String>{};
    final prereq = <String, Set<String>>{};
    for (final s in template.stages) {
      for (final u in s.unlocks) {
        prereq.putIfAbsent(u, () => <String>{}).add(s.id);
      }
    }
    final completed = <String>{};
    final queue = <String>[for (final s in template.entryStages) s.id];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (unlocked.contains(id)) continue;
      unlocked.add(id);
      final stage = template.stages.firstWhere((e) => e.id == id);
      final p = progress[id];
      final done = p != null &&
          p.hands >= stage.minHands &&
          p.accuracy >= stage.requiredAccuracy;
      if (done) {
        completed.add(id);
        for (final next in stage.unlocks) {
          final deps = prereq[next] ?? const <String>{};
          if (deps.every(completed.contains)) queue.add(next);
        }
      }
    }
    return unlocked;
  }

  String _accKey(String pathId, String stageId) =>
      'training_path_v2_${pathId}_$stageId_acc';
  String _handsKey(String pathId, String stageId) =>
      'training_path_v2_${pathId}_$stageId_hands';
}

class _StageProgress {
  final double accuracy;
  final int hands;
  const _StageProgress({required this.accuracy, required this.hands});
}
