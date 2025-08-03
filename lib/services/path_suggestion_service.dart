import '../models/learning_path_template_v2.dart';
import 'learning_path_registry_service.dart';

/// Stub service that will later suggest the next learning path.
class PathSuggestionService {
  PathSuggestionService._();
  static final instance = PathSuggestionService._();

  /// Returns next recommended [LearningPathTemplateV2] or `null` if none.
  Future<LearningPathTemplateV2?> nextPath() async {
    // Currently returns the second template as a simple placeholder suggestion.
    final templates = await LearningPathRegistryService.instance.loadAll();
    if (templates.length < 2) return null;
    return templates[1];
  }
}
