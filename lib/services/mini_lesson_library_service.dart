import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_mini_lesson_node.dart';
import 'theory_mini_lesson_factory_service.dart';
import 'theory_lesson_completion_logger.dart';
import 'mini_lesson_progress_tracker.dart';

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

  /// Returns training pack ids linked to [lessonId].
  List<String> linkedPacksFor(String lessonId) =>
      _byId[lessonId]?.linkedPackIds ?? const [];

  /// Returns `true` if the lesson with [lessonId] has been completed.
  Future<bool> isLessonCompleted(String lessonId) async {
    return MiniLessonProgressTracker.instance.isCompleted(lessonId);
  }

  /// Suggests the next lesson that has not been completed yet.
  Future<TheoryMiniLessonNode?> getNextLesson() async {
    await loadAll();
    final completions = await TheoryLessonCompletionLogger.instance
        .getCompletions();
    final completedIds = completions.map((e) => e.lessonId).toSet();
    for (final lesson in _lessons) {
      if (!completedIds.contains(lesson.id)) return lesson;
    }
    return null;
  }

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
    final factory = const TheoryMiniLessonFactoryService();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final node = factory.fromYaml(Map<String, dynamic>.from(map));
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

  /// Returns the first lesson matching [tag], or `null` if none found.
  TheoryMiniLessonNode? findLessonByTag(String tag) {
    final direct = _byTag[tag];
    if (direct != null && direct.isNotEmpty) return direct.first;
    final lower = tag.toLowerCase();
    for (final entry in _byTag.entries) {
      if (entry.key.toLowerCase() == lower && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }
}

extension MiniLessonLibraryFetch on MiniLessonLibraryService {
  /// Loads and returns all available lessons.
  Future<List<TheoryMiniLessonNode>> getAllLessons() async {
    await loadAll();
    return all;
  }
}

extension MiniLessonLibraryProgress on MiniLessonLibraryService {
  Future<int> getTotalLessonCount() async {
    await loadAll();
    return all.length;
  }

  Future<int> getCompletedLessonCount() async {
    await loadAll();
    final completed = await TheoryLessonCompletionLogger.instance
        .getCompletedLessons();
    return completed.keys.where((id) => getById(id) != null).length;
  }
}
