import '../models/learning_path_stage_model.dart';
import '../models/stage_type.dart';
import 'booster_thematic_tagger.dart';
import 'theory_pack_generator_service.dart';
import 'training_path_storage_service.dart';

/// Generates basic theory stages for key tags and saves them to storage.
class TheoryPathStageSeeder {
  final BoosterThematicTagger tagger;
  final TheoryPackGeneratorService generator;
  final TrainingPathStorageService storage;

  TheoryPathStageSeeder({
    this.tagger = const BoosterThematicTagger(),
    this.generator = const TheoryPackGeneratorService(),
    this.storage = const TrainingPathStorageService(),
  });

  Future<void> seedAll() async {
    final tags = TheoryPackGeneratorService.tags;
    final stages = <LearningPathStageModel>[];
    var order = 0;
    for (final tag in tags) {
      final tpl = generator.generateForTag(tag);
      stages.add(
        LearningPathStageModel(
          id: 'theory_$tag',
          title: '📘 ${tpl.name}',
          description: tpl.description,
          packId: tpl.id,
          type: StageType.theory,
          requiredAccuracy: 0,
          minHands: 0,
          tags: [tag],
          order: order++,
        ),
      );
    }
    await storage.save('core_path', stages);
  }
}
