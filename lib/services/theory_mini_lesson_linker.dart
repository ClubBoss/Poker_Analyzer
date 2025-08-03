import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'mini_lesson_library_service.dart';
import 'pack_library_loader_service.dart';

/// Links theory mini lessons with training packs based on shared tags and stage.
class TheoryMiniLessonLinker {
  static const String _cacheKey = 'theory_mini_lesson_links';

  final MiniLessonLibraryService library;
  final PackLibraryLoaderService loader;

  const TheoryMiniLessonLinker({
    this.library = MiniLessonLibraryService.instance,
    this.loader = PackLibraryLoaderService.instance,
  });

  /// Computes pack links for all lessons and persists results.
  Future<void> link({bool force = false}) async {
    await library.loadAll();
    final packs = await loader.loadLibrary();

    final prefs = await PreferencesService.getInstance();
    if (!force) {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        for (final lesson in library.all) {
          final ids = data[lesson.id];
          lesson.linkedPackIds = [
            for (final v in (ids as List? ?? [])) v.toString()
          ];
        }
        return;
      }
    }

    final map = <String, List<String>>{};
    for (final lesson in library.all) {
      final stage = lesson.stage ?? _extractStage(lesson.tags);
      final lessonTags = {
        for (final t in lesson.tags) t.toLowerCase().trim()
      }..removeWhere(_isStageTag);

      final links = <String>[];
      for (final pack in packs) {
        final packStage = _packStage(pack);
        if (stage != null && packStage != null && stage != packStage) {
          continue;
        }
        final packTags = {
          for (final t in pack.tags) t.toLowerCase().trim()
        }..removeWhere(_isStageTag);
        if (packTags.intersection(lessonTags).isNotEmpty) {
          links.add(pack.id);
        }
      }
      lesson.linkedPackIds = links;
      if (links.isNotEmpty) map[lesson.id] = links;
    }

    await prefs.setString(_cacheKey, jsonEncode(map));
  }

  bool _isStageTag(String tag) =>
      RegExp(r'^level\\d+\$', caseSensitive: false).hasMatch(tag);

  String? _extractStage(List<String> tags) {
    for (final t in tags) {
      final s = t.toLowerCase();
      if (_isStageTag(s)) return s;
    }
    return null;
  }

  String? _packStage(TrainingPackTemplateV2 pack) {
    final metaStage = pack.meta['stage']?.toString();
    if (metaStage != null && metaStage.isNotEmpty) {
      return metaStage.toLowerCase();
    }
    return _extractStage(pack.tags);
  }
}
