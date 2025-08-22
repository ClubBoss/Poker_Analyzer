import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import 'mini_lesson_library_builder.dart';

/// Groups [MiniLessonEntry] objects into YAML packs by tag prefix.
class MiniLessonPackGenerator {
  final MiniLessonLibraryBuilder builder;
  final YamlReader reader;
  final YamlWriter writer;

  MiniLessonPackGenerator({
    MiniLessonLibraryBuilder? builder,
    YamlReader? reader,
    YamlWriter? writer,
  }) : builder = builder ?? const MiniLessonLibraryBuilder(),
       reader = reader ?? const YamlReader(),
       writer = writer ?? const YamlWriter();

  String _groupKey(String tag) {
    final match = RegExp(r'^[^:_]+').firstMatch(tag);
    return match?.group(0) ?? tag;
  }

  Future<List<File>> generate(
    List<MiniLessonEntry> entries, {
    String dir = 'yaml_out',
    Map<String, String> titles = const {},
    Map<String, String> merge = const {},
  }) async {
    final groups = <String, List<MiniLessonEntry>>{};
    for (final e in entries) {
      final key = _groupKey(e.tag.toLowerCase());
      groups.putIfAbsent(key, () => []).add(e);
    }

    final files = <File>[];
    await Directory(dir).create(recursive: true);

    for (final key in groups.keys) {
      final list = groups[key]!;
      final title = titles[key] ?? key;
      final packId =
          'mini_lessons_${key.replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';

      final existing = <MiniLessonEntry>[];
      final mergePath = merge[key];
      if (mergePath != null && File(mergePath).existsSync()) {
        try {
          final raw = await File(mergePath).readAsString();
          final map = reader.read(raw);
          final lessons = map['lessons'];
          if (lessons is List) {
            for (final l in lessons) {
              if (l is Map) {
                final tag = (l['tags'] as List?)?.first ?? key;
                final title = l['title']?.toString() ?? '';
                final content = l['content']?.toString() ?? '';
                final examples =
                    (l['examples'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    const <String>[];
                existing.add(
                  MiniLessonEntry(
                    tag: tag,
                    title: title,
                    content: content,
                    examples: examples,
                  ),
                );
              }
            }
          }
        } catch (_) {}
      }

      final combined = [...existing, ...list];
      final lessonsYaml = builder.buildYaml(combined, autoPriority: true);
      final lessonMap = reader.read(lessonsYaml);
      final outMap = {
        'pack_id': packId,
        'title': title,
        'type': 'theory',
        'lessons': lessonMap['lessons'],
      };
      final path = p.join(dir, '$packId.yaml');
      await writer.write(outMap, path);
      files.add(File(path));
    }

    return files;
  }
}
