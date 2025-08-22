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
  LearningPathGatekeeperService({
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

    // Map stage id to model for quick lookup
    final stageById = {for (final s in template.stages) s.id: s};

    if (template.sections.isNotEmpty) {
      final idsInSections = <String>{};
      for (var i = 0; i < template.sections.length; i++) {
        final section = template.sections[i];
        idsInSections.addAll(section.stageIds);
        var allow = true;
        if (i > 0) {
          final prev = template.sections[i - 1];
          allow = prev.stageIds.every((id) => progress.getStageCompletion(id));
        }
        if (!allow) continue;
        for (final id in section.stageIds) {
          final stage = stageById[id];
          if (stage == null) continue;
          if (stage.unlockAfter.isNotEmpty &&
              !stage.unlockAfter.every(progress.getStageCompletion)) {
            continue;
          }
          if (!_meetsMastery(stage, masteryMap)) continue;
          if (_isBlocked(stage, blockedClusters)) continue;
          if (!_meetsSessionCount()) continue;
          _unlocked.add(stage.id);
        }
      }

      // Process stages not assigned to any section
      for (final stage in template.stages) {
        if (idsInSections.contains(stage.id)) continue;
        if (!base.contains(stage.id)) continue;
        if (stage.unlockAfter.isNotEmpty &&
            !stage.unlockAfter.every(progress.getStageCompletion)) {
          continue;
        }
        if (!_meetsMastery(stage, masteryMap)) continue;
        if (_isBlocked(stage, blockedClusters)) continue;
        if (!_meetsSessionCount()) continue;
        _unlocked.add(stage.id);
      }
    } else {
      for (final stage in template.stages) {
        if (!base.contains(stage.id)) continue;
        if (stage.unlockAfter.isNotEmpty &&
            !stage.unlockAfter.every(progress.getStageCompletion)) {
          continue;
        }
        if (!_meetsMastery(stage, masteryMap)) continue;
        if (_isBlocked(stage, blockedClusters)) continue;
        if (!_meetsSessionCount()) continue;
        _unlocked.add(stage.id);
      }
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
