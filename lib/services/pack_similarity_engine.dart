import '../models/v2/training_pack_template_v2.dart';
import 'package:collection/collection.dart';
import 'pack_library_index_loader.dart';

/// Provides simple similarity search over training packs.
class PackSimilarityEngine {
  const PackSimilarityEngine({List<TrainingPackTemplateV2>? library})
      : _library = library;
  final List<TrainingPackTemplateV2>? _library;

  /// Finds packs similar to [packId] using pre-loaded library packs.
  /// Similarity weight:
  /// - tag overlap: 0.5
  /// - audience match: 0.3
  /// - difficulty closeness: 0.2
  /// Returns up to five packs sorted by descending similarity.
  List<TrainingPackTemplateV2> findSimilar(String packId) {
    final library = _library ?? PackLibraryIndexLoader.instance.library;
    if (library.isEmpty) return [];
    final base = library.firstWhereOrNull((p) => p.id == packId);
    if (base == null) return [];

    final baseTags = {for (final t in base.tags) t.trim().toLowerCase()};
    final baseAudience =
        (base.audience ?? base.meta['audience']?.toString() ?? '')
            .trim()
            .toLowerCase();
    final baseDifficulty = _difficulty(base);

    final scored = <(TrainingPackTemplateV2, double)>[];
    for (final p in library) {
      if (p.id == base.id) continue;
      final tags = {for (final t in p.tags) t.trim().toLowerCase()};
      final tagInter = tags.intersection(baseTags).length.toDouble();
      final tagUnion = tags.union(baseTags).length.toDouble();
      final tagScore = tagUnion == 0 ? 0 : tagInter / tagUnion;

      final audience = (p.audience ?? p.meta['audience']?.toString() ?? '')
          .trim()
          .toLowerCase();
      final audienceScore = baseAudience.isEmpty && audience.isEmpty
          ? 1.0
          : (audience.isNotEmpty && audience == baseAudience ? 1.0 : 0.0);

      final diff = _difficulty(p);
      var diffScore = 1 - (diff - baseDifficulty).abs() / 3.0;
      if (diffScore < 0) diffScore = 0;

      final score = tagScore * 0.5 + audienceScore * 0.3 + diffScore * 0.2;
      scored.add((p, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(5)) s.$1];
  }

  int _difficulty(TrainingPackTemplateV2 pack) {
    final v = pack.meta['difficulty'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
