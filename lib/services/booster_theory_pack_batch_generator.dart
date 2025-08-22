import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'theory_pack_generator.dart';

/// Generates missing theory packs for a list of tags.
class BoosterTheoryPackBatchGenerator {
  final TheoryPackGenerator _generator;

  BoosterTheoryPackBatchGenerator({TheoryPackGenerator? generator})
    : _generator = generator ?? const TheoryPackGenerator();

  /// Returns [library] extended with theory packs for every tag in [tags]
  /// that doesn't already exist. Newly created pack ids are prefixed with
  /// [idPrefix].
  List<TrainingPackTemplateV2> generate(
    List<TrainingPackTemplateV2> library,
    List<String> tags, {
    String idPrefix = 'auto',
  }) {
    final existingTags = <String>{};
    final existingIds = <String>{};
    for (final tpl in library) {
      existingIds.add(tpl.id);
      if (tpl.trainingType != TrainingType.theory) continue;
      for (final t in tpl.tags) {
        final tag = t.trim().toLowerCase();
        if (tag.isNotEmpty) existingTags.add(tag);
      }
    }

    final newPacks = <TrainingPackTemplateV2>[];
    for (final tag in tags) {
      final key = tag.trim().toLowerCase();
      if (key.isEmpty || existingTags.contains(key)) continue;

      var prefix = idPrefix;
      var attempt = 1;
      TrainingPackTemplateV2 pack;
      do {
        pack = _generator.generate(tag, prefix);
        prefix = '$idPrefix${attempt++}';
      } while (existingIds.contains(pack.id));

      pack.trainingType = const TrainingTypeEngine().detectTrainingType(pack);
      newPacks.add(pack);
      existingTags.add(key);
      existingIds.add(pack.id);
    }

    return [...library, ...newPacks];
  }
}
