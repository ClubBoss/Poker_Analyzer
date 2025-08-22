import 'package:flutter/foundation.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'booster_pack_library_builder.dart';
import 'dev_console_log_service.dart';
import 'theory_yaml_importer.dart';

/// Controls the generation and import pipeline for booster content.
class BoosterContentPipelineController {
  BoosterContentPipelineController({
    BoosterPackLibraryBuilder? builder,
    TheoryYamlImporter? importer,
  }) : _builder = builder ?? const BoosterPackLibraryBuilder(),
       _importer = importer ?? const TheoryYamlImporter();

  final BoosterPackLibraryBuilder _builder;
  final TheoryYamlImporter _importer;

  /// Generates boosters from [basePacks], imports them from [outputDir]
  /// and returns the list of imported templates.
  ///
  /// Logs summary information to the DevConsole.
  Future<List<TrainingPackTemplateV2>> runPipeline({
    required List<TrainingPackTemplateV2> basePacks,
    required List<TrainingPackTemplateV2> theoryPacks,
    required String outputDir,
  }) async {
    await _builder.generateAllBoosters(
      basePacks: basePacks,
      theoryPacks: theoryPacks,
      outputDir: outputDir,
    );

    final imported = await _importer.importFromDirectory(outputDir);

    final names = imported.map((e) => e.name).join(', ');
    final msg =
        'Generated ${imported.length} boosters using ${theoryPacks.length} theory packs: $names';
    debugPrint(msg);
    DevConsoleLogService.instance.log(msg);
    return imported;
  }
}
