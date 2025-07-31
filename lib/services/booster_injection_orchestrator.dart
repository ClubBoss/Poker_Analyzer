import '../models/learning_path_block.dart';
import 'booster_inventory_service.dart';
import 'tag_mastery_service.dart';
import 'skill_gap_detector_service.dart';
import 'smart_booster_recall_engine.dart';
import 'learning_path_stage_library.dart';
import 'path_map_engine.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Selects booster previews to inject into a stage flow.
class BoosterInjectionOrchestrator {
  final TagMasteryService mastery;
  final BoosterInventoryService inventory;
  final SkillGapDetectorService gaps;
  final SmartBoosterRecallEngine recall;

  final Set<String> _shown = <String>{};

  BoosterInjectionOrchestrator({
    required this.mastery,
    required this.inventory,
    SkillGapDetectorService? gaps,
    SmartBoosterRecallEngine? recall,
  })  : gaps = gaps ?? SkillGapDetectorService(),
        recall = recall ?? SmartBoosterRecallEngine.instance;

  /// Returns booster blocks relevant to [stage].
  Future<List<LearningPathBlock>> getInjectableBoosters(StageNode stage) async {
    await inventory.loadAll();

    final model = LearningPathStageLibrary.instance.getById(stage.id);
    if (model == null) return [];

    final stageTags = <String>{
      for (final t in model.tags) t.trim().toLowerCase()
    }..removeWhere((t) => t.isEmpty);
    if (stageTags.isEmpty) return [];

    final masteryMap = await mastery.computeMastery();
    final weakTags = masteryMap.entries
        .where((e) => e.value < 0.6)
        .map((e) => e.key)
        .toSet();

    final gapTags = (await gaps.getMissingTags()).toSet();

    final recallable = await recall.getRecallableTypes(DateTime.now());

    final targetTags = <String>{}
      ..addAll(stageTags.intersection({...weakTags, ...gapTags}))
      ..addAll(recallable.where(stageTags.contains));

    if (targetTags.isEmpty) return [];

    final candidates = <TrainingPackTemplateV2>[];
    for (final tag in targetTags) {
      candidates.addAll(inventory.findByTag(tag));
    }

    if (candidates.isEmpty) return [];

    final unique = <TrainingPackTemplateV2>[];
    final seen = <String>{};
    for (final b in candidates) {
      if (unique.length >= 2) break;
      if (seen.contains(b.id) || _shown.contains(b.id)) continue;
      unique.add(b);
      seen.add(b.id);
      _shown.add(b.id);
    }

    return [
      for (final b in unique)
        LearningPathBlock(
          id: b.id,
          header: b.name,
          content: b.description,
          ctaLabel: 'Начать',
          lessonId: b.id,
          injectedInStageId: stage.id,
        )
    ];
  }
}
