import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_mini_lesson_node.dart';

/// Loads and indexes mini lesson blocks stored as YAML files.
class MiniLessonLibraryService {
  MiniLessonLibraryService._();
  static final MiniLessonLibraryService instance = MiniLessonLibraryService._();

  static const List<String> _dirs = [
    'assets/mini_lessons/',
    'assets/theory_mini_lessons/',
    'assets/theory_lessons/level1/',
  ];

  final List<TheoryMiniLessonNode> _lessons = [];
  final Map<String, TheoryMiniLessonNode> _byId = {};
  final Map<String, List<TheoryMiniLessonNode>> _byTag = {};

  List<TheoryMiniLessonNode> get all => List.unmodifiable(_lessons);

  TheoryMiniLessonNode? getById(String id) => _byId[id];

  Future<void> loadAll() async {
    if (_lessons.isNotEmpty) return;
    await reload();
  }

  Future<void> reload() async {
    _lessons.clear();
    _byId.clear();
    _byTag.clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => _dirs.any((d) => p.startsWith(d)) && p.endsWith('.yaml'))
        .toList();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final node = TheoryMiniLessonNode.fromYaml(
          Map<String, dynamic>.from(map),
        );
        if (node.id.isEmpty) continue;
        _lessons.add(node);
        _byId[node.id] = node;
        for (final t in node.tags) {
          final list = _byTag.putIfAbsent(t, () => []);
          list.add(node);
        }
      } catch (_) {}
    }
  }

  /// Returns lessons matching any of [tags], in insertion order.
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final seen = <String>{};
    final result = <TheoryMiniLessonNode>[];
    for (final t in tags) {
      final list = _byTag[t] ?? const [];
      for (final n in list) {
        if (seen.add(n.id)) result.add(n);
      }
    }
    return result;
  }

  /// Returns lessons matching any of [tags]. Convenience for Set input.
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}
