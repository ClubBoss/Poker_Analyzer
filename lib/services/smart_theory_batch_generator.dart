import '../models/pack_library.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'smart_theory_pack_generator.dart';
import 'theory_template_index.dart';

/// Generates missing theory packs for all known tags.
class SmartTheoryBatchGenerator {
  final SmartTheoryPackGenerator generator;
  final int batchSize;

  const SmartTheoryBatchGenerator({
    this.generator = const SmartTheoryPackGenerator(),
    this.batchSize = 20,
  });

  /// Generates theory packs for missing tags and adds them to [PackLibrary.staging].
  /// Returns the list of newly created packs.
  Future<List<TrainingPackTemplateV2>> generateMissing({
    List<String>? tags,
  }) async {
    final list = tags ?? TheoryTemplateIndex.tags;
    final created = <TrainingPackTemplateV2>[];
    var count = 0;
    for (final tag in list) {
      if (count >= batchSize) break;
      final key = tag.trim().toLowerCase();
      if (key.isEmpty) continue;
      final sanitized = key.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final id = 'theory_$sanitized';
      final existing =
          PackLibrary.main.getById(id) ?? PackLibrary.staging.getById(id);
      if (existing != null) continue;
      final pack = await generator.generateTheoryPack(tag);
      PackLibrary.staging.add(pack);
      created.add(pack);
      count++;
    }
    return created;
  }
}
