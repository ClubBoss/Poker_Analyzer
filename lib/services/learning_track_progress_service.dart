import '../models/learning_track_progress_model.dart';
import 'learning_path_gatekeeper_service.dart';
import 'learning_path_registry_service.dart';
import 'training_path_progress_service_v2.dart';

/// Builds [LearningTrackProgressModel] for a learning path.
class LearningTrackProgressService {
  final TrainingPathProgressServiceV2 progress;
  final LearningPathGatekeeperService gatekeeper;
  final LearningPathRegistryService registry;
  String? _currentPathId;

  const LearningTrackProgressService({
    required this.progress,
    required this.gatekeeper,
    LearningPathRegistryService? registry,
  }) : registry = registry ?? LearningPathRegistryService.instance;

  Future<LearningTrackProgressModel> build(String pathId) async {
    _currentPathId = pathId;
    await progress.loadProgress(pathId);
    await gatekeeper.updateStageUnlocks(pathId);
    final template = registry.findById(pathId);
    if (template == null) {
      return const LearningTrackProgressModel(stages: []);
    }
    final unlocked = progress.unlockedStageIds().toSet();
    final statuses = <StageProgressStatus>[];
    for (final stage in template.stages) {
      final completed = progress.getStageCompletion(stage.id);
      final isUnlocked =
          unlocked.contains(stage.id) && gatekeeper.isStageUnlocked(stage.id);
      final status = completed
          ? StageStatus.completed
          : (isUnlocked ? StageStatus.unlocked : StageStatus.locked);
      statuses.add(StageProgressStatus(stageId: stage.id, status: status));
    }
    return LearningTrackProgressModel(stages: statuses);
  }

  /// Marks [stageId] completed and recomputes stage unlocks.
  Future<void> advanceToNextStage(String stageId) async {
    if (_currentPathId == null) return;
    final acc = progress.getStageAccuracy(stageId);
    await progress.markStageCompleted(stageId, acc);
    await gatekeeper.updateStageUnlocks(_currentPathId!);
  }
}
