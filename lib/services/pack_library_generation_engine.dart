import 'dart:convert';
import 'dart:io';
import '../core/training/generation/yaml_reader.dart';
import 'pack_validation_engine.dart';

class PackLibraryGenerationEngine {
  const PackLibraryGenerationEngine();

  Future<void> generate({
    required String inputDir,
    required String outputPath,
    String? audience,
    List<String>? tags,
  }) async {
    final dir = Directory(inputDir);
    if (!dir.existsSync()) return;
    const reader = YamlReader();
    final reqTags = tags?.map((e) => e.trim().toLowerCase()).toSet() ?? {};
    final list = <Map<String, dynamic>>[];
    for (final f in dir.listSync(recursive: true).whereType<File>().where((e) =>
        e.path.toLowerCase().endsWith('.yaml') ||
        e.path.toLowerCase().endsWith('.yml'))) {
      try {
        final templates = await reader.loadTemplates(f.path);
        for (final tpl in templates) {
          final report = const PackValidationEngine().validate(tpl);
          if (!report.isValid) continue;
          if (audience != null && audience.isNotEmpty) {
            final a = tpl.audience;
            if (a != null && a.isNotEmpty && a != audience) continue;
          }
          if (reqTags.isNotEmpty) {
            final tplTags = <String>{
              for (final t in tpl.tags) t.trim().toLowerCase()
            };
            if (!reqTags.every(tplTags.contains)) continue;
          }
          list.add(tpl.toJson());
        }
      } catch (_) {}
    }
    final file = File(outputPath)..createSync(recursive: true);
    await file.writeAsString(jsonEncode(list), flush: true);
  }
}
