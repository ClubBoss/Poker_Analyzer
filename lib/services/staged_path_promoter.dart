import '../models/learning_path_template_v2.dart';
import 'learning_path_library.dart';

/// Moves staged learning paths from [LearningPathLibrary.staging] into
/// [LearningPathLibrary.main] so they are accessible in the app.
class StagedPathPromoter {
  StagedPathPromoter();

  /// Copies all templates from the staging library into the main library.
  ///
  /// When [prefix] is provided, only templates with IDs starting with
  /// the prefix are promoted. Existing entries with the same `id`
  /// are overwritten.
  int promoteAll({String? prefix}) {
    final staging = List<LearningPathTemplateV2>.from(
      LearningPathLibrary.staging.paths,
    );
    final main = LearningPathLibrary.main;
    main.clear();
    var count = 0;
    for (final tpl in staging) {
      if (prefix != null && !tpl.id.startsWith(prefix)) {
        continue;
      }
      main.remove(tpl.id);
      main.add(tpl);
      count++;
    }
    return count;
  }
}
