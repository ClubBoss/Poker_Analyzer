import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/v2/training_pack_template_v2.dart';
import 'theory_pack_generator_service.dart';
import 'theory_yaml_safe_reader.dart';

/// Generates a JSON index for theory YAML packs in `yaml_out/`.
class TheoryTemplateIndex {
  TheoryTemplateIndex();

  /// List of all known theory tags.
  static List<String> get tags => TheoryPackGeneratorService.tags;

  /// Scans [dir] for theory YAML packs and writes `theory_index.json`.
  /// Returns the number of indexed files.
  Future<int> generateJsonIndex({String dir = 'yaml_out'}) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return 0;
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    final list = <Map<String, dynamic>>[];
    for (final file in files) {
      try {
        final map = await TheoryYamlSafeReader().read(
          path: file.path,
          schema: 'TemplateSet',
        );
        final tpl = TrainingPackTemplateV2.fromJson(map);
        list.add({
          'id': tpl.id,
          'tags': tpl.tags,
          'title': tpl.name,
          'lang': tpl.meta['lang'] ?? 'en',
          'filename': p.basename(file.path),
        });
      } catch (_) {}
    }
    final outFile = File(p.join(directory.path, 'theory_index.json'))
      ..createSync(recursive: true);
    await outFile.writeAsString(jsonEncode(list), flush: true);
    return list.length;
  }
}
