import '../models/v2/training_pack_template_v2.dart';

/// In-memory registry of training pack templates.
///
/// This simple library stores generated [TrainingPackTemplateV2] instances
/// during runtime. It does not persist data and is primarily used by seeders or
/// tests that need a lightweight template repository.
class TrainingPackTemplateLibraryService {
  TrainingPackTemplateLibraryService._();

  /// Singleton instance.
  static final TrainingPackTemplateLibraryService instance =
      TrainingPackTemplateLibraryService._();

  final Map<String, TrainingPackTemplateV2> _templates = {};

  /// Returns all stored templates.
  List<TrainingPackTemplateV2> get templates =>
      List.unmodifiable(_templates.values);

  /// Retrieves a template by [id] or `null` if missing.
  TrainingPackTemplateV2? getById(String id) => _templates[id];

  /// Adds [template] to the library if its id is not already present.
  void add(TrainingPackTemplateV2 template) {
    _templates.putIfAbsent(template.id, () => template);
  }

  /// Clears all stored templates. Primarily used in tests.
  void clear() => _templates.clear();
}

