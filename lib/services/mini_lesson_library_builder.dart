import 'dart:io';

import '../utils/mini_lesson_node_builder.dart';
import '../core/training/generation/yaml_writer.dart';
import 'package:yaml/yaml.dart';

/// Simple data holder for mini lesson source information.
class MiniLessonEntry {
  final String tag;
  final String title;
  final String content;
  final List<String> examples;

  const MiniLessonEntry({
    required this.tag,
    required this.title,
    required this.content,
    this.examples = const [],
  });

  MiniLessonEntry copyWith({
    String? tag,
    String? title,
    String? content,
    List<String>? examples,
  }) {
    return MiniLessonEntry(
      tag: tag ?? this.tag,
      title: title ?? this.title,
      content: content ?? this.content,
      examples: examples ?? this.examples,
    );
  }
}

/// Generates YAML libraries of mini lessons from basic text snippets.
class MiniLessonLibraryBuilder {
  final MiniLessonNodeBuilder nodeBuilder;
  final YamlWriter writer;

  const MiniLessonLibraryBuilder({
    MiniLessonNodeBuilder? nodeBuilder,
    YamlWriter? yamlWriter,
  })  : nodeBuilder = nodeBuilder ?? const MiniLessonNodeBuilder(),
        writer = yamlWriter ?? const YamlWriter();

  /// Builds a list of YAML compatible lesson maps.
  List<Map<String, dynamic>> _buildList(
    List<MiniLessonEntry> entries, {
    bool autoPriority = false,
    bool deduplicate = true,
  }) {
    final seen = <String>{};
    final list = <Map<String, dynamic>>[];
    var prio = 1;
    for (final e in entries) {
      final key = '${e.tag.toLowerCase()}|${e.title.toLowerCase()}';
      if (deduplicate && !seen.add(key)) continue;
      list.add(nodeBuilder.toYamlMap(
        tag: e.tag,
        title: e.title,
        content: e.content,
        priority: autoPriority ? prio++ : null,
        examples: e.examples.isEmpty ? null : e.examples,
      ));
    }
    return list;
  }

  /// Returns YAML for the given [entries].
  String buildYaml(
    List<MiniLessonEntry> entries, {
    bool autoPriority = false,
    bool deduplicate = true,
  }) {
    final map = {
      'lessons': _buildList(entries,
          autoPriority: autoPriority, deduplicate: deduplicate)
    };
    return const YamlEncoder().convert(map);
  }

  /// Writes the generated YAML to [path]. Returns the created file.
  Future<File> saveTo(
    String path,
    List<MiniLessonEntry> entries, {
    bool autoPriority = false,
    bool deduplicate = true,
  }) async {
    final map = {
      'lessons': _buildList(entries,
          autoPriority: autoPriority, deduplicate: deduplicate)
    };
    await writer.write(map, path);
    return File(path);
  }
}
