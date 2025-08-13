import 'package:flutter/services.dart' show rootBundle;

import '../core/training/generation/yaml_reader.dart';
import '../models/learning_path_stage_model.dart';
import 'learning_path_stage_library.dart';

class LearningPathStageSeeder {
  const LearningPathStageSeeder();

  Future<void> seedStages(List<String> yamlPaths,
      {required String audience}) async {
    final reader = const YamlReader();
    final library = LearningPathStageLibrary.instance;
    library.clear();
    var order = 0;
    for (final path in yamlPaths) {
      try {
        final tpl = await reader.loadTemplate(path);
        if (tpl.audience != null &&
            tpl.audience!.isNotEmpty &&
            tpl.audience != audience) {
          continue;
        }
        final stage = LearningPathStageModel(
          id: tpl.id,
          title: tpl.name,
          description: tpl.description,
          packId: tpl.id,
          requiredAccuracy: 80,
          minHands: 10,
          tags: tpl.tags,
          order: order,
        );
        library.add(stage);
        order++;
      } catch (_) {}
    }
  }

  Future<void> seedFromConfig({required String audience}) async {
    try {
      final raw =
          await rootBundle.loadString('assets/learning_path_tracks.yaml');
      final map = const YamlReader().read(raw);
      final key = audience.toLowerCase();
      final paths = [for (final p in (map[key] as List? ?? [])) p.toString()];
      await seedStages(paths, audience: audience);
    } catch (_) {}
  }
}
