import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

/// Links theory packs to learning path stages based on tags.
class BoosterTheoryPackLinker {
  BoosterTheoryPackLinker();

  /// Returns [template] with [LearningPathStageModel.theoryPackId] filled
  /// whenever a matching theory pack exists in [library].
  LearningPathTemplateV2 link(
    LearningPathTemplateV2 template,
    List<TrainingPackTemplateV2> library,
  ) {
    final tagToPack = <String, String>{};
    for (final pack in library) {
      if (pack.trainingType != TrainingType.theory) continue;
      for (final tag in pack.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isNotEmpty) tagToPack[key] = pack.id;
      }
    }

    final stages = <LearningPathStageModel>[];
    for (final stage in template.stages) {
      if (stage.theoryPackId != null) {
        stages.add(stage);
        continue;
      }
      String? theoryId;
      final tags = stage.tags.isEmpty ? template.tags : stage.tags;
      for (final tag in tags) {
        final key = tag.trim().toLowerCase();
        final id = tagToPack[key];
        if (id != null) {
          theoryId = id;
          break;
        }
      }
      if (theoryId != null) {
        stages.add(
          LearningPathStageModel(
            id: stage.id,
            title: stage.title,
            description: stage.description,
            packId: stage.packId,
            theoryPackId: theoryId,
            boosterTheoryPackIds: stage.boosterTheoryPackIds,
            requiredAccuracy: stage.requiredAccuracy,
            minHands: stage.minHands,
            subStages: stage.subStages,
            unlocks: stage.unlocks,
            unlockAfter: stage.unlockAfter,
            tags: stage.tags,
            objectives: stage.objectives,
            order: stage.order,
            isOptional: stage.isOptional,
            unlockCondition: stage.unlockCondition,
            type: stage.type,
          ),
        );
      } else {
        stages.add(stage);
      }
    }

    return LearningPathTemplateV2(
      id: template.id,
      title: template.title,
      description: template.description,
      stages: stages,
      sections: template.sections,
      tags: template.tags,
      recommendedFor: template.recommendedFor,
      prerequisitePathIds: template.prerequisitePathIds,
      coverAsset: template.coverAsset,
      difficulty: template.difficulty,
    );
  }
}
