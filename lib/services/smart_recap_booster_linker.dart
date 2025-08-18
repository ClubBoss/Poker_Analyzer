import '../models/v2/training_pack_template_v2.dart';
import '../models/theory_mini_lesson_node.dart';
import 'training_pack_template_storage_service.dart';
import 'pack_library_loader_service.dart';

/// Links recap lessons with relevant booster packs based on shared tags.
class SmartRecapBoosterLinker {
  final TrainingPackTemplateStorageService storage;
  final PackLibraryLoaderService library;

  const SmartRecapBoosterLinker({
    required this.storage,
    this.library = PackLibraryLoaderService.instance,
  });

  /// Returns booster packs matching lesson tags sorted by pack size ascending.
  Future<List<TrainingPackTemplateV2>> getBoostersForLesson(
    TheoryMiniLessonNode lesson,
  ) async {
    final tags = {for (final t in lesson.tags) t.trim().toLowerCase()}
      ..removeWhere((t) => t.isEmpty);
    if (tags.isEmpty) return [];

    await storage.load();
    await library.loadLibrary();

    final builtIn = {for (final p in library.library) p.id: p};
    final result = <TrainingPackTemplateV2>[];

    for (final model in storage.templates) {
      final raw = model.filters['tags'];
      final tplTags = <String>[
        for (final t in (raw as List? ?? [])) t.toString(),
      ];
      final tplTagSet = {for (final t in tplTags) t.trim().toLowerCase()}
        ..removeWhere((t) => t.isEmpty);
      if (tplTagSet.isEmpty) continue;
      if (tplTagSet.intersection(tags).isEmpty) continue;
      final builtin = builtIn[model.id];
      if (builtin != null && builtin.spotCount <= 10) {
        result.add(builtin);
      } else {
        try {
          final tpl = await storage.loadBuiltinTemplate(model.id);
          if (tpl.spotCount <= 10 &&
              tpl.tags.any((t) => tags.contains(t.toLowerCase()))) {
            result.add(tpl);
          }
        } catch (_) {}
      }
    }

    result.sort((a, b) => a.spotCount.compareTo(b.spotCount));
    return result;
  }
}
