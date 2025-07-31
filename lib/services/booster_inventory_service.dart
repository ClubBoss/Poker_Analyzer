import '../models/v2/training_pack_template_v2.dart';
import 'booster_library_service.dart';

/// Provides access to available booster training packs.
class BoosterInventoryService {
  final BoosterLibraryService library;

  BoosterInventoryService({this.library = BoosterLibraryService.instance});

  /// Loads booster packs from the underlying library.
  Future<void> loadAll({int limit = 500}) => library.loadAll(limit: limit);

  /// Returns all boosters with [tag] in their metadata.
  List<TrainingPackTemplateV2> findByTag(String tag) => library.findByTag(tag);

  /// Returns booster pack by [id] or `null`.
  TrainingPackTemplateV2? getById(String id) => library.getById(id);

  /// Returns all loaded booster packs.
  List<TrainingPackTemplateV2> get all => library.all;
}
