import 'dart:io';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

class YamlPackAutoTagger {
  final YamlReader reader;
  final YamlWriter writer;
  const YamlPackAutoTagger({YamlReader? yamlReader, YamlWriter? yamlWriter})
      : reader = yamlReader ?? const YamlReader(),
        writer = yamlWriter ?? const YamlWriter();

  List<String> generateTags(TrainingPackTemplateV2 pack) {
    final set = <String>{...pack.tags};
    final category = pack.category?.trim();
    if (category != null && category.isNotEmpty) {
      set.add('cat:$category');
    }
    for (final p in pack.positions) {
      final pos = p.trim();
      if (pos.isNotEmpty) set.add('position:$pos');
    }
    final aud = pack.audience?.trim();
    if (aud != null && aud.isNotEmpty) set.add(aud);
    if (pack.trainingType == TrainingType.pushFold) set.add('pushfold');
    final total = pack.meta['totalWeight'] as int? ?? pack.spots.length;
    if (total > 0) {
      final ev = (pack.meta['evCovered'] as int? ?? 0) * 100 ~/ total;
      final icm = (pack.meta['icmCovered'] as int? ?? 0) * 100 ~/ total;
      set.add('ev:${(ev ~/ 5) * 5}');
      set.add('icm:${(icm ~/ 5) * 5}');
    }
    final text = '${pack.name} ${pack.description}'.toLowerCase();
    if (text.contains('defense')) set.add('blindDefense');
    if (text.contains('3bet') || text.contains('3-бет')) set.add('3bet');
    if (text.contains('push')) set.add('push');
    if (text.contains('call')) set.add('call');
    if (text.contains('fold')) set.add('fold');
    final list = set.toList()..sort();
    return list;
  }

  void generateAll(
    List<TrainingPackTemplateV2> packs, {
    bool overwrite = false,
  }) {
    for (final p in packs) {
      p.tags = generateTags(p);
    }
    if (overwrite) {
      for (final p in packs) {
        final file = File(p.meta['path']?.toString() ?? '');
        if (file.existsSync()) {
          writer.write(p.toJson(), file.path);
        }
      }
    }
  }
}
