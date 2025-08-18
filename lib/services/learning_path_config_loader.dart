import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/learning_path_stage_model.dart';
import 'learning_path_stage_library.dart';

/// Loads learning path configurations from YAML files and registers stages.
class LearningPathConfigLoader {
  LearningPathConfigLoader._();

  static final instance = LearningPathConfigLoader._();

  /// Loads stages from [yamlPath] and registers them in [LearningPathStageLibrary].
  Future<void> loadPath(String yamlPath) async {
    final library = LearningPathStageLibrary.instance;
    library.clear();
    try {
      final raw = await rootBundle.loadString(yamlPath);
      final yaml = loadYaml(raw);
      if (yaml is! Map) return;
      final packPaths = [
        for (final p in (yaml['packs'] as List? ?? [])) p.toString(),
      ];
      final reader = const YamlReader();
      var index = 0;
      for (final path in packPaths) {
        try {
          final tpl = await reader.loadTemplate(path);
          final stage = LearningPathStageModel(
            id: tpl.id,
            title: tpl.name,
            description: tpl.description,
            packId: tpl.id,
            requiredAccuracy: 80,
            minHands: 10,
            tags: tpl.tags,
            order: index,
          );
          library.add(stage);
          index++;
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Loads all default learning paths.
  Future<void> loadAllPaths() async {
    final library = LearningPathStageLibrary.instance;
    library.clear();
    const paths = [
      'assets/learning_paths/beginner_path.yaml',
      'assets/learning_paths/icm_postflop_path.yaml',
      'assets/learning_paths/live_path.yaml',
      'assets/learning_paths/cash_path.yaml',
    ];
    for (final p in paths) {
      await loadPath(p);
    }
  }
}
