import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_spot.dart';

/// Provides access to training spots stored in the built-in library.
class TrainingPackRepository {
  const TrainingPackRepository();

  /// Returns all spots that contain [tag] in their tag list.
  Future<List<TrainingPackSpot>> getSpotsByTag(String tag) async {
    final lower = tag.trim().toLowerCase();
    if (lower.isEmpty) return [];
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final result = <TrainingPackSpot>[];
    for (final pack in TrainingPackLibraryV2.instance.packs) {
      for (final s in pack.spots) {
        if (s.tags.any((t) => t.toLowerCase() == lower)) {
          result.add(TrainingPackSpot.fromJson(s.toJson()));
        }
      }
    }
    return result;
  }
}
