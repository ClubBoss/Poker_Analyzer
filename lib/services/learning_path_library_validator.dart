import 'learning_path_library.dart';
import 'learning_path_template_validator.dart';

/// Validates a [LearningPathLibrary] using [LearningPathTemplateValidator].
class LearningPathLibraryValidator {
  LearningPathLibraryValidator();

  /// Returns a list of `(pathId, message)` tuples describing issues.
  List<(String, String)> validateAll(LearningPathLibrary library) {
    final validator = const LearningPathTemplateValidator();
    final issues = <(String, String)>[];
    for (final path in library.paths) {
      for (final issue in validator.validate(path)) {
        issues.add((path.id, issue.message));
      }
    }
    return issues;
  }
}
