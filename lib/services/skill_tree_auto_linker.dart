import '../models/v2/training_pack_spot.dart';

/// Naively links spots to skill tags for later processing.
class SkillTreeAutoLinker {
  const SkillTreeAutoLinker();

  /// Writes the spot's tags into `skillTags` meta field.
  void linkAll(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      if (s.tags.isNotEmpty) {
        s.meta['skillTags'] = List<String>.from(s.tags);
      }
    }
  }
}

