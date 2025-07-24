import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import '../core/training/generation/yaml_reader.dart';
import '../models/learning_path_stage_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'learning_path_stage_library.dart';

class LearningPathStageSeeder {
  const LearningPathStageSeeder();

  Future<void> seedStages(List<String> yamlPaths, {required String audience}) async {
    final reader = const YamlReader();
    final library = LearningPathStageLibrary.instance;
    library.clear();
    var order = 0;
    for (final path in yamlPaths) {
      try {
        final source = path.startsWith('assets/')
            ? await rootBundle.loadString(path)
            : await File(path).readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(source);
        if (tpl.audience != null && tpl.audience!.isNotEmpty && tpl.audience != audience) {
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
}
