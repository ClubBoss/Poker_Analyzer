import '../core/training/library/training_pack_library_v2.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';

/// Provides access to all training packs in the built-in library.
class TrainingPackLibraryService {
  final TrainingPackLibraryV2 _library;

  TrainingPackLibraryService({TrainingPackLibraryV2? library})
      : _library = library ?? TrainingPackLibraryV2.instance;

  /// Loads and returns all packs as [TrainingPackModel]s.
  Future<List<TrainingPackModel>> getAllPacks() async {
    await _library.loadFromFolder();
    return [
      for (final tpl in _library.packs)
        TrainingPackModel(
          id: tpl.id,
          title: tpl.name,
          spots: List<TrainingPackSpot>.from(tpl.spots),
          tags: List<String>.from(tpl.tags),
          metadata: Map<String, dynamic>.from(tpl.meta),
        ),
    ];
  }
}
