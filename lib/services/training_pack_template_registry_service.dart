import '../models/training_pack_template_set.dart';
import 'training_pack_template_set_library_service.dart';

/// Provides lookup utilities for [TrainingPackTemplateSet]s.
class TrainingPackTemplateRegistryService {
  final TrainingPackTemplateSetLibraryService _library;

  TrainingPackTemplateRegistryService({
    TrainingPackTemplateSetLibraryService? library,
  }) : _library = library ?? TrainingPackTemplateSetLibraryService.instance;

  /// Loads a [TrainingPackTemplateSet] by its [templateId].
  ///
  /// Throws a [StateError] if no template with the given id exists.
  Future<TrainingPackTemplateSet> loadTemplateById(String templateId) async {
    await _library.loadAll();
    try {
      return _library.all
          .firstWhere((s) => s.baseSpot.id == templateId);
    } catch (_) {
      throw StateError('Template not found: $templateId');
    }
  }
}
