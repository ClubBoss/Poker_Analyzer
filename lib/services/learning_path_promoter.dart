import 'learning_path_library.dart';

/// Updates [target] library with paths from [staged] when IDs match.
class LearningPathPromoter {
  LearningPathPromoter();

  /// Replaces entries in [target] with staged versions that share the same id.
  /// Returns the number of paths that were updated.
  int promoteStaged({
    required LearningPathLibrary staged,
    required LearningPathLibrary target,
  }) {
    var count = 0;
    for (final tpl in staged.paths) {
      if (target.getById(tpl.id) != null) {
        target.remove(tpl.id);
        target.add(tpl);
        count++;
      }
    }
    LearningPathLibrary.main = target;
    return count;
  }
}
