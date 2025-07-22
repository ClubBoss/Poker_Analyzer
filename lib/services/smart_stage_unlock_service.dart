import '../models/learning_path_template_v2.dart';
import '../models/session_log.dart';
import 'learning_path_stage_gatekeeper_service.dart';

/// Computes additional stage unlocks based on player's weakest tags.
class SmartStageUnlockService {
  final LearningPathStageGatekeeperService gatekeeper;
  final double weaknessThreshold;
  final int maxPerTag;

  const SmartStageUnlockService({
    this.gatekeeper = const LearningPathStageGatekeeperService(),
    this.weaknessThreshold = 0.6,
    this.maxPerTag = 1,
  });

  /// Returns IDs of stages that should be unlocked early for reinforcement.
  List<String> getAdditionalUnlockedStageIds({
    required Map<String, SessionLog> progress,
    required Map<String, double> skillMap,
    required LearningPathTemplateV2 path,
  }) {
    final completed = <String>{};
    final defaultUnlocked = <String>{};

    for (var i = 0; i < path.stages.length; i++) {
      final stage = path.stages[i];
      final log = progress[stage.packId];
      final hands = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
      final accuracy = hands == 0 ? 0.0 : (log!.correctCount / hands) * 100;
      final done = hands >= stage.minHands && accuracy >= stage.requiredAccuracy;
      if (done) completed.add(stage.id);
      if (gatekeeper.isStageUnlocked(
        index: i,
        path: path,
        logs: progress,
      )) {
        defaultUnlocked.add(stage.id);
      }
    }

    // Determine current section index
    int currentIndex = 0;
    for (var i = 0; i < path.stages.length; i++) {
      final id = path.stages[i].id;
      if (defaultUnlocked.contains(id) && !completed.contains(id)) {
        currentIndex = i;
        break;
      }
    }

    final sectionByStage = <String, int>{};
    for (var i = 0; i < path.sections.length; i++) {
      final s = path.sections[i];
      for (final id in s.stageIds) {
        sectionByStage[id] = i;
      }
    }
    final currentSection = sectionByStage[path.stages[currentIndex].id] ?? 0;

    final unlockedPerTag = <String, int>{};
    final additional = <String>[];

    for (var i = 0; i < path.stages.length; i++) {
      final stage = path.stages[i];
      if (completed.contains(stage.id) || defaultUnlocked.contains(stage.id)) {
        continue;
      }
      final sectionIndex = sectionByStage[stage.id] ?? currentSection;
      if ((sectionIndex - currentSection).abs() > 1) continue;
      bool weak = false;
      for (final tag in stage.tags) {
        final key = tag.toLowerCase();
        final skill = skillMap[key] ?? 1.0;
        if (skill < weaknessThreshold &&
            (unlockedPerTag[key] ?? 0) < maxPerTag) {
          unlockedPerTag[key] = (unlockedPerTag[key] ?? 0) + 1;
          weak = true;
          break;
        }
      }
      if (weak) additional.add(stage.id);
    }

    return additional;
  }
}
