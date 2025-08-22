import 'dart:io';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../utils/training_pack_yaml_codec_v2.dart';
import 'training_pack_template_service.dart';

/// Generates precompiled training packs and stores them as YAML files
/// under `assets/precompiled_packs/`.
class PrecompiledPackCacheGenerator {
  PrecompiledPackCacheGenerator();

  /// Generates YAML files for all available [TrainingPackTemplate]s.
  Future<void> generateAll() async {
    final templates = TrainingPackTemplateService.getAllTemplates();
    final dir = Directory('assets/precompiled_packs');
    await dir.create(recursive: true);
    const codec = TrainingPackYamlCodecV2();

    for (final tpl in templates) {
      try {
        final spots = await tpl.generateSpots();
        final expanded = tpl.copyWith({
          'spots': spots,
          'spotCount': spots.length,
        });
        final v2 = TrainingPackTemplateV2.fromTemplate(
          expanded,
          type: TrainingType.pushFold,
        );
        v2.trainingType = const TrainingTypeEngine().detectTrainingType(v2);
        final yaml = codec.encode(v2);
        final file = File('${dir.path}/${tpl.id}.yaml');
        await file.writeAsString(yaml);
      } catch (_) {
        // Ignore failures for individual templates.
      }
    }
  }
}
