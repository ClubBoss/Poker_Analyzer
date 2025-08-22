import '../models/v2/training_pack_template_v2.dart';
import 'tag_mastery_service.dart';
import 'training_pack_template_service.dart';
import 'pack_library_index_loader.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';

class LearningPathBoosterEngine {
  final List<TrainingPackTemplateV2>? _libraryOverride;

  LearningPathBoosterEngine({List<TrainingPackTemplateV2>? library})
    : _libraryOverride = library;

  Future<List<TrainingPackTemplateV2>> getBoosterPacks({
    required TagMasteryService mastery,
    required int maxPacks,
  }) async {
    final library = _libraryOverride ?? await _loadLibrary();
    final masteryMap = await mastery.computeMastery();
    final entries = <MapEntry<TrainingPackTemplateV2, double>>[];

    for (final p in library) {
      var weakness = 0.0;
      for (final tag in p.tags) {
        final m = masteryMap[tag.toLowerCase()];
        if (m != null) weakness += 1 - m;
      }
      if (weakness == 0) continue;
      final importance = (p.meta['rankScore'] as num?)?.toDouble() ?? 1.0;
      entries.add(MapEntry(p, weakness * importance));
    }

    entries.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(maxPacks)) e.key];
  }

  Future<List<TrainingPackTemplateV2>> _loadLibrary() async {
    await PackLibraryIndexLoader.instance.load();
    await TrainingPackLibraryV2.instance.loadFromFolder();

    final builtIn = TrainingPackTemplateService.getAllTemplates();
    final builtInV2 = <TrainingPackTemplateV2>[];
    for (final t in builtIn) {
      builtInV2.add(
        TrainingPackTemplateV2.fromTemplate(t, type: TrainingType.pushFold),
      );
    }

    final index = PackLibraryIndexLoader.instance.library;
    final all = <TrainingPackTemplateV2>[...builtInV2];
    final ids = {for (final p in all) p.id};
    for (final p in index) {
      if (ids.add(p.id)) all.add(p);
    }
    return all;
  }
}
