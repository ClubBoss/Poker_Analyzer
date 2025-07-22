
import '../models/learning_path_stage_model.dart';
import '../services/learning_path_registry_service.dart';
import '../services/training_path_progress_service_v2.dart';
import '../services/tag_mastery_service.dart';
import '../services/mistake_tag_history_service.dart';
import '../services/mistake_tag_cluster_service.dart';
import '../models/mistake_tag_cluster.dart';

/// Controls unlocking of learning path stages based on progress, mastery
/// and mistake patterns.
class LearningPathGatekeeperService {
  final TrainingPathProgressServiceV2 progress;
  final TagMasteryService mastery;
  final MistakeTagClusterService clusterService;
  final double masteryThreshold;
  final int mistakeThreshold;
  final int minSessions;

  /// Creates a gatekeeper using [progress] and [mastery].
  const LearningPathGatekeeperService({
    required this.progress,
    required this.mastery,
    this.clusterService = const MistakeTagClusterService(),
    this.masteryThreshold = 0.6,
    this.mistakeThreshold = 5,
    this.minSessions = 0,
  });

  final Set<String> _unlocked = <String>{};

  /// Returns `true` if [stageId] is currently unlocked.
  bool isStageUnlocked(String stageId) => _unlocked.contains(stageId);

  /// Recomputes unlocked stages for [pathId].
  Future<void> updateStageUnlocks(String pathId) async {
    await progress.loadProgress(pathId);
    final template = LearningPathRegistryService.instance.findById(pathId);
    if (template == null) {
      _unlocked.clear();
      return;
    }

    final base = progress.unlockedStageIds().toSet();
    final masteryMap = await mastery.computeMastery();
    final freq = await MistakeTagHistoryService.getTagsByFrequency();

    final blockedClusters = <MistakeTagCluster>{};
    for (final entry in freq.entries) {
      if (entry.value >= mistakeThreshold) {
        blockedClusters.add(clusterService.getClusterForTag(entry.key));
      }
    }

    _unlocked.clear();
    for (final stage in template.stages) {
      if (!base.contains(stage.id)) continue;
      if (!_meetsMastery(stage, masteryMap)) continue;
      if (_isBlocked(stage, blockedClusters)) continue;
      if (!_meetsSessionCount()) continue;
      _unlocked.add(stage.id);
    }
  }

  bool _meetsMastery(
    LearningPathStageModel stage,
    Map<String, double> masteryMap,
  ) {
    for (final t in stage.tags) {
      final m = masteryMap[t.toLowerCase()] ?? 1.0;
      if (m < masteryThreshold) return false;
    }
    return true;
  }

  bool _isBlocked(
    LearningPathStageModel stage,
    Set<MistakeTagCluster> blocked,
  ) {
    if (blocked.isEmpty) return false;
    for (final c in blocked) {
      if (stage.tags.any((t) => t.toLowerCase() == c.label.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _meetsSessionCount() {
    if (minSessions <= 0) return true;
    return progress.logs.logs.length >= minSessions;
  }
}

