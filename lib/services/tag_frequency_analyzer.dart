import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class TagFrequencyAnalyzer {
  TagFrequencyAnalyzer();

  Future<void> generate({
    String src = 'assets/packs/v2',
    String out = 'assets/packs/v2/tag_frequencies.json',
  }) async {
    final tagCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    void addTag(String tag) => tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    void addCategory(String tag) =>
        categoryCounts[tag] = (categoryCounts[tag] ?? 0) + 1;
    var processed = false;
    final indexFile = File(p.join(src, 'library_index.json'));
    if (indexFile.existsSync()) {
      try {
        final list = jsonDecode(await indexFile.readAsString());
        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              for (final t in item['tags'] as List? ?? []) {
                addTag(t.toString());
              }
              final c = (item['mainTag'] ?? item['category'])?.toString();
              if (c != null && c.isNotEmpty) addCategory(c);
            }
          }
          processed = true;
        }
      } catch (_) {}
    }
    if (!processed) {
      final dir = Directory(src);
      if (dir.existsSync()) {
        const reader = YamlReader();
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.yaml'));
        for (final f in files) {
          try {
            final yaml = await f.readAsString();
            final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
            if (tpl.meta['manualSource'] == true) continue;
            for (final t in tpl.tags) {
              addTag(t);
            }
            final c =
                tpl.category ?? (tpl.tags.isNotEmpty ? tpl.tags.first : null);
            if (c != null && c.isNotEmpty) addCategory(c);
            processed = true;
          } catch (_) {}
        }
      }
    }
    final sortedTags = Map.fromEntries(
      tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    final sortedCategories = Map.fromEntries(
      categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
    final file = File(out)..createSync(recursive: true);
    file.writeAsStringSync(
      jsonEncode({'tags': sortedTags, 'categories': sortedCategories}),
    );
  }
}
