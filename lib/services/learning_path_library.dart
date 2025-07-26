import '../models/learning_path_template_v2.dart';

/// In-memory library for learning path templates.
class LearningPathLibrary {
  LearningPathLibrary._();

  /// Staging library used during development.
  static final LearningPathLibrary staging = LearningPathLibrary._();

  /// Main library for promoted paths.
  static final LearningPathLibrary main = LearningPathLibrary._();

  final List<LearningPathTemplateV2> _paths = [];
  final Map<String, LearningPathTemplateV2> _index = {};

  /// Unmodifiable view of stored templates.
  List<LearningPathTemplateV2> get paths => List.unmodifiable(_paths);

  /// Clears all templates from this library.
  void clear() {
    _paths.clear();
    _index.clear();
  }

  /// Adds [template] if its id is not already present.
  void add(LearningPathTemplateV2 template) {
    if (_index.containsKey(template.id)) return;
    _paths.add(template);
    _index[template.id] = template;
  }

  /// Adds all templates from [list].
  void addAll(Iterable<LearningPathTemplateV2> list) {
    for (final tpl in list) {
      add(tpl);
    }
  }

  /// Removes template with [id] if present.
  void remove(String id) {
    final tpl = _index.remove(id);
    if (tpl != null) _paths.remove(tpl);
  }

  /// Returns template with [id] if stored.
  LearningPathTemplateV2? getById(String id) => _index[id];
}
