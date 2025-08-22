import '../models/v2/training_pack_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'pack_library_service.dart';

class SkillGapBoosterService {
  final PackLibraryService _library;
  const SkillGapBoosterService({PackLibraryService? library})
    : _library = library ?? PackLibraryService.instance;

  Future<List<TrainingPackTemplateV2>> suggestBoosters({
    required List<String> requiredTags,
    required Map<String, double> masteryMap,
    int count = 1,
  }) async {
    if (requiredTags.isEmpty) return [];

    // Use library service to ensure all YAML packs are loaded.
    await _library.recommendedStarter();
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final packs = TrainingPackLibraryV2.instance.filterBy(
      type: TrainingType.pushFold,
    );

    final weakTags = <String>{
      for (final t in requiredTags)
        if ((masteryMap[t.toLowerCase()] ?? 0) < 0.4) t.toLowerCase(),
    };
    if (weakTags.isEmpty) return [];

    final scored = <_ScoredPack>[];
    for (final p in packs) {
      final spotCount = p.spots.isNotEmpty ? p.spots.length : p.spotCount;
      if (spotCount >= 10) continue;
      final tags = {for (final t in p.tags) t.toLowerCase()};
      final overlap = tags.intersection(weakTags);
      if (overlap.isEmpty) continue;
      final coverage = overlap.length / weakTags.length;
      scored.add(_ScoredPack(pack: p, coverage: coverage));
    }

    scored.sort((a, b) {
      final cmp = b.coverage.compareTo(a.coverage);
      if (cmp != 0) return cmp;
      final ac = a.pack.spots.isNotEmpty
          ? a.pack.spots.length
          : a.pack.spotCount;
      final bc = b.pack.spots.isNotEmpty
          ? b.pack.spots.length
          : b.pack.spotCount;
      return ac.compareTo(bc);
    });

    return [for (final s in scored.take(count)) s.pack];
  }
}

class _ScoredPack {
  final TrainingPackTemplateV2 pack;
  final double coverage;
  const _ScoredPack({required this.pack, required this.coverage});
}
