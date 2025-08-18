import 'dart:io';

import '../models/v2/training_pack_template_v2.dart';
import 'theory_booster_generator.dart';

/// Generates booster packs from a list of base packs and saves them as YAML files.
class BoosterPackLibraryBuilder {
  final TheoryBoosterGenerator _generator;

  const BoosterPackLibraryBuilder({TheoryBoosterGenerator? generator})
    : _generator = generator ?? const TheoryBoosterGenerator();

  /// Generates a booster pack for every item in [basePacks] using the
  /// provided [theoryPacks] as sources of theory content. The resulting packs
  /// are saved to [outputDir] with filenames based on the base pack name and
  /// the `_booster.yaml` suffix. A `generatedBy` field is added to each pack's
  /// meta information.
  Future<void> generateAllBoosters({
    required List<TrainingPackTemplateV2> basePacks,
    required List<TrainingPackTemplateV2> theoryPacks,
    required String outputDir,
  }) async {
    final dir = Directory(outputDir);
    await dir.create(recursive: true);

    for (final base in basePacks) {
      final booster = _generator.generateBooster(
        basePack: base,
        allTheoryPacks: theoryPacks,
      );
      booster.meta = Map<String, dynamic>.from(booster.meta)
        ..['generatedBy'] = 'BoosterPackLibraryBuilder v1';

      final safeName = base.name
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(' ', '_')
          .toLowerCase();
      final file = File('${dir.path}/$safeName_booster.yaml');
      await file.writeAsString(booster.toYamlString());
    }
  }
}
