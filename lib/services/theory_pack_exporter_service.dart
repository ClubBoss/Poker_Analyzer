import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/theory_mini_lesson_node.dart';

/// Exports [TheoryMiniLessonNode]s into YAML files grouped by stage or theme.
class TheoryPackExporterService {
  final YamlEncoder _encoder;

  const TheoryPackExporterService({YamlEncoder? encoder})
      : _encoder = encoder ?? const YamlEncoder();

  /// Saves [lessons] into [outputDir] grouped by [groupBy].
  ///
  /// When [groupBy] is `'stage'` lessons are grouped by their [stage] field.
  /// When `'cluster'` lessons are clustered using tag overlap and next links.
  /// Returns list of created file paths.
  Future<List<String>> export(
    List<TheoryMiniLessonNode> lessons,
    String outputDir, {
    String groupBy = 'stage',
  }) async {
    final dir = Directory(outputDir);
    await dir.create(recursive: true);

    final groups = groupBy == 'cluster'
        ? _groupByCluster(lessons)
        : _groupByStage(lessons);

    final result = <String>[];
    for (final entry in groups.entries) {
      final name = groupBy == 'stage'
          ? 'stage_${_sanitize(entry.key)}.yaml'
          : '${entry.key}.yaml';
      final file = File('${dir.path}/$name');
      final yaml = _encoder.convert({
        'lessons': [for (final l in entry.value) _lessonToMap(l)],
      });
      await file.writeAsString(yaml);
      result.add(file.path);
    }
    return result;
  }

  Map<String, List<TheoryMiniLessonNode>> _groupByStage(
    List<TheoryMiniLessonNode> lessons,
  ) {
    final map = <String, List<TheoryMiniLessonNode>>{};
    for (final l in lessons) {
      final key = (l.stage ?? 'none').trim();
      map.putIfAbsent(key.isEmpty ? 'none' : key, () => []).add(l);
    }
    return map;
  }

  Map<String, List<TheoryMiniLessonNode>> _groupByCluster(
    List<TheoryMiniLessonNode> lessons,
  ) {
    final byId = {for (final l in lessons) l.id: l};
    final adj = <String, Set<String>>{
      for (final l in lessons) l.id: <String>{},
    };

    final tagIndex = <String, List<String>>{};
    for (final l in lessons) {
      for (final t in l.tags) {
        final key = t.trim().toLowerCase();
        if (key.isEmpty) continue;
        tagIndex.putIfAbsent(key, () => []).add(l.id);
      }
    }
    for (final ids in tagIndex.values) {
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          adj[ids[i]]!.add(ids[j]);
          adj[ids[j]]!.add(ids[i]);
        }
      }
    }

    for (final l in lessons) {
      for (final next in l.nextIds) {
        if (byId.containsKey(next)) {
          adj[l.id]!.add(next);
          adj[next]!.add(l.id);
        }
      }
    }

    final visited = <String>{};
    final groups = <String, List<TheoryMiniLessonNode>>{};
    var idx = 1;
    for (final id in byId.keys) {
      if (!visited.add(id)) continue;
      final stack = <String>[id];
      final ids = <String>[];
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        ids.add(cur);
        for (final n in adj[cur] ?? {}) {
          if (visited.add(n)) stack.add(n);
        }
      }
      groups['cluster_${idx++}'] = [for (final cid in ids) byId[cid]!];
    }
    return groups;
  }

  Map<String, dynamic> _lessonToMap(TheoryMiniLessonNode l) => {
        'id': l.id,
        'title': l.title,
        if (l.tags.isNotEmpty) 'tags': l.tags,
        if (l.stage != null && l.stage!.isNotEmpty) 'stage': l.stage,
        if (l.content.isNotEmpty) 'content': l.content,
        if (l.linkedPackIds.isNotEmpty) 'linkedPackIds': l.linkedPackIds,
      };

  String _sanitize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
