import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/generation/yaml_reader.dart';

Future<void> main(List<String> args) async {
  final src = args.isNotEmpty ? args[0] : 'assets/packs/v2';
  final out = args.length > 1
      ? args[1]
      : 'assets/packs/v2/tag_frequencies.json';
  final tagCounts = <String, int>{};
  final categoryCounts = <String, int>{};
  void addTag(String tag) => tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
  void addCategory(String tag) =>
      categoryCounts[tag] = (categoryCounts[tag] ?? 0) + 1;
  Future<void> processTemplate(TrainingPackTemplateV2 tpl) async {
    if (tpl.meta['manualSource'] == true) return;
    for (final t in tpl.tags) {
      addTag(t);
    }
    final c = tpl.category ?? (tpl.tags.isNotEmpty ? tpl.tags.first : null);
    if (c != null && c.isNotEmpty) addCategory(c);
  }

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
          final map = reader.read(await f.readAsString());
          final tpl = TrainingPackTemplateV2.fromJson(map);
          await processTemplate(tpl);
          processed = true;
        } catch (_) {}
      }
    }
  }
  final sortedTags = Map.fromEntries(
    tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
  final sortedCategories = Map.fromEntries(
    categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
  final file = File(out)..createSync(recursive: true);
  file.writeAsStringSync(
    jsonEncode({'tags': sortedTags, 'categories': sortedCategories}),
  );
  stdout.writeln(
    'Wrote ${sortedTags.length} tags and ${sortedCategories.length} categories to ${p.normalize(out)}',
  );
}
