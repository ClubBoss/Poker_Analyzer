import 'dart:io';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Exports theory mini lessons as a Graphviz DOT graph.
class TheoryLessonGraphExporter {
  final MiniLessonLibraryService library;

  TheoryLessonGraphExporter({MiniLessonLibraryService? library})
      : library = library ?? MiniLessonLibraryService.instance;

  /// Generates the DOT representation of all lessons in [library].
  ///
  /// When [clusterByTag] is true, lessons are grouped into clusters using
  /// their first tag as label.
  Future<String> generateDotGraph({bool clusterByTag = false}) async {
    await library.loadAll();
    final lessons = library.all;
    final buffer = StringBuffer('digraph theory {\n');

    if (clusterByTag) {
      final Map<String, List<TheoryMiniLessonNode>> byTag = {};
      for (final l in lessons) {
        final tag = l.tags.isNotEmpty ? l.tags.first : 'other';
        byTag.putIfAbsent(tag, () => []).add(l);
      }
      for (final entry in byTag.entries) {
        buffer.writeln('  subgraph "cluster_${entry.key}" {');
        buffer.writeln('    label="${_escape(entry.key)}";');
        for (final l in entry.value) {
          final labelTag = l.tags.isNotEmpty ? l.tags.first : '';
          final label = labelTag.isNotEmpty
              ? '${_escape(labelTag)}\\n${_escape(l.title)}'
              : _escape(l.title);
          buffer.writeln('    "${l.id}" [label="$label"];');
        }
        buffer.writeln('  }');
      }
    } else {
      for (final l in lessons) {
        final tag = l.tags.isNotEmpty ? l.tags.first : '';
        final label = tag.isNotEmpty
            ? '${_escape(tag)}\\n${_escape(l.title)}'
            : _escape(l.title);
        buffer.writeln('  "${l.id}" [label="$label"];');
      }
    }

    for (final l in lessons) {
      for (final next in l.nextIds) {
        buffer.writeln('  "${l.id}" -> "$next";');
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Saves the generated DOT graph to [path] and returns the created file.
  Future<File> saveToFile(String path, {bool clusterByTag = false}) async {
    final dot = await generateDotGraph(clusterByTag: clusterByTag);
    final file = File(path);
    await file.writeAsString(dot);
    return file;
  }

  String _escape(String value) => value.replaceAll('"', '\\"');
}
