import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import '../models/stage_type.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'learning_path_library.dart';
import 'theory_yaml_importer.dart';

/// Builds theory-only learning paths from YAML packs.
class TheoryStageAutoSeeder {
  final TheoryYamlImporter importer;
  final String dir;
  final int maxStages;

  TheoryStageAutoSeeder({
    TheoryYamlImporter? importer,
    this.dir = 'yaml_out/theory',
    this.maxStages = 12,
  }) : importer = importer ?? const TheoryYamlImporter();

  /// Loads theory packs from [dir], groups them by tag and saves generated
  /// paths into [LearningPathLibrary.staging].
  Future<List<LearningPathTemplateV2>> seed() async {
    final templates = await importer.importFromDirectory(dir);
    final groups = <String, List<TrainingPackTemplateV2>>{};
    for (final tpl in templates) {
      if (tpl.trainingType != TrainingType.theory) continue;
      if (tpl.id.trim().isEmpty) continue;
      if (tpl.tags.isEmpty) continue;
      final tag = tpl.tags.first.trim().toLowerCase();
      groups.putIfAbsent(tag, () => []).add(tpl);
    }

    final library = LearningPathLibrary.staging;
    library.clear();

    final result = <LearningPathTemplateV2>[];
    for (final entry in groups.entries) {
      final tag = entry.key;
      final sanitized = tag.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final packs = entry.value..sort((a, b) => a.name.compareTo(b.name));
      var order = 0;
      final stages = <LearningPathStageModel>[];
      for (final p in packs.take(maxStages)) {
        stages.add(
          LearningPathStageModel(
            id: p.id,
            title: p.name,
            description: p.description,
            packId: p.id,
            type: StageType.theory,
            requiredAccuracy: 0,
            minHands: 0,
            tags: p.tags,
            order: order++,
          ),
        );
      }
      final tpl = LearningPathTemplateV2(
        id: 'theory_path_$sanitized',
        title: 'Theory: $tag',
        description: '',
        stages: stages,
        tags: [tag],
      );
      library.add(tpl);
      result.add(tpl);
    }
    return result;
  }
}
