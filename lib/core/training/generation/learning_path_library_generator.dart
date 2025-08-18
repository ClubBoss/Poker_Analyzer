import 'package:json2yaml/json2yaml.dart';

import 'learning_path_stage_template_generator.dart';
import 'yaml_reader.dart';

/// Input model for a learning path stage.
class LearningPathStageTemplateInput {
  final String id;
  final String title;
  final String packId;
  final String description;
  final double requiredAccuracy;
  final int minHands;
  final List<SubStageTemplateInput> subStages;
  final UnlockConditionInput? unlockCondition;
  final List<String>? tags;
  final List<String>? objectives;

  const LearningPathStageTemplateInput({
    required this.id,
    required this.title,
    required this.packId,
    this.description = '',
    this.requiredAccuracy = 80,
    this.minHands = 10,
    this.subStages = const [],
    this.unlockCondition,
    this.tags,
    this.objectives,
  });
}

/// Generates a learning path YAML file from stage templates.
class LearningPathLibraryGenerator {
  final LearningPathStageTemplateGenerator stageGenerator;
  const LearningPathLibraryGenerator({
    LearningPathStageTemplateGenerator? stageGenerator,
  }) : stageGenerator = stageGenerator ?? LearningPathStageTemplateGenerator();

  /// Generates YAML for a complete learning path based on [stages].
  String generatePathYaml(List<LearningPathStageTemplateInput> stages) {
    stageGenerator.reset();
    final stageMaps = <Map<String, dynamic>>[];
    for (final s in stages) {
      final yaml = stageGenerator.generateStageYaml(
        id: s.id,
        title: s.title,
        packId: s.packId,
        description: s.description,
        requiredAccuracy: s.requiredAccuracy,
        minHands: s.minHands,
        subStages: s.subStages,
        unlockCondition: s.unlockCondition,
        objectives: s.objectives,
        tags: s.tags,
      );
      final map = const YamlReader().read(yaml);
      stageMaps.add(Map<String, dynamic>.from(map));
    }
    final tags = <String>{};
    for (final m in stageMaps) {
      for (final t in (m['tags'] as List? ?? [])) {
        final tag = t.toString().trim();
        if (tag.isNotEmpty) tags.add(tag);
      }
    }
    final pathMap = <String, dynamic>{'stages': stageMaps};
    if (tags.isNotEmpty) pathMap['tags'] = tags.toList()..sort();
    return json2yaml(pathMap, yamlStyle: YamlStyle.pubspecYaml);
  }
}
