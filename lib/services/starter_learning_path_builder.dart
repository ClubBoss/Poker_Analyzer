import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import '../models/learning_track_section_model.dart';
import 'theory_pack_library_service.dart';
import 'theory_pack_stage_injector.dart';

/// Builds a minimal starter learning path from embedded theory packs.
class StarterLearningPathBuilder {
  final TheoryPackLibraryService theoryLibrary;
  final TheoryPackStageInjector injector;

  StarterLearningPathBuilder({
    TheoryPackLibraryService? theoryLibrary,
    this.injector = const TheoryPackStageInjector(),
  }) : theoryLibrary = theoryLibrary ?? TheoryPackLibraryService.instance;

  LearningPathTemplateV2 build() {
    final packs = [
      for (final p in theoryLibrary.all)
        if (p.tags.contains('starter')) p,
    ];

    final stages = <LearningPathStageModel>[];
    final stageIds = <String>[];
    var order = 0;
    for (final pack in packs) {
      var stage = injector.injectFromTheoryPack(pack);
      stage = _withOrder(stage, order++);
      stages.add(stage);
      stageIds.add(stage.id);
    }

    stages.sort((a, b) => a.order.compareTo(b.order));

    final section = LearningTrackSectionModel(
      id: 'starter_section',
      title: 'Getting Started',
      description: '',
      stageIds: stageIds,
    );

    return LearningPathTemplateV2(
      id: 'starter_path',
      title: 'Getting Started',
      description: '',
      stages: stages,
      sections: [section],
    );
  }

  LearningPathStageModel _withOrder(LearningPathStageModel s, int order) {
    return LearningPathStageModel(
      id: s.id,
      title: s.title,
      description: s.description,
      packId: s.packId,
      theoryPackId: s.theoryPackId,
      boosterTheoryPackIds: s.boosterTheoryPackIds,
      requiredAccuracy: s.requiredAccuracy,
      minHands: s.minHands,
      subStages: s.subStages,
      unlocks: s.unlocks,
      unlockAfter: s.unlockAfter,
      tags: s.tags,
      objectives: s.objectives,
      order: order,
      isOptional: s.isOptional,
      unlockCondition: s.unlockCondition,
      type: s.type,
    );
  }
}
