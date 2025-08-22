import '../models/training_pack_meta.dart';
import '../core/training/engine/training_type_engine.dart';
import 'training_pack_index_service.dart';

/// Provides search capabilities over indexed training packs.
class TrainingPackLibrarySearchService {
  final TrainingPackIndexService _indexService;

  TrainingPackLibrarySearchService({
    TrainingPackIndexService? indexService,
  }) : _indexService = indexService ?? TrainingPackIndexService.instance;

  /// Returns all training packs that match the provided filters.
  ///
  /// [includeTags] - All tags that must be present on a pack.
  /// [skillLevel] - Skill level filter.
  /// [trainingType] - Training type filter.
  List<TrainingPackMeta> search({
    List<String> includeTags = const [],
    String? skillLevel,
    TrainingType? trainingType,
  }) {
    return _indexService.getAll().where((pack) {
      final matchesTags = includeTags.every((t) => pack.tags.contains(t));
      final matchesSkill = skillLevel == null || pack.skillLevel == skillLevel;
      final matchesType =
          trainingType == null || pack.trainingType == trainingType;
      return matchesTags && matchesSkill && matchesType;
    }).toList();
  }
}
