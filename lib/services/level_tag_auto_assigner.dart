import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

/// Assigns a level to training packs based on their tags or training type.
class LevelTagAutoAssigner {
  LevelTagAutoAssigner();

  /// Updates `meta['level']` for each [templates] item and returns the list.
  List<TrainingPackTemplateV2> assign(List<TrainingPackTemplateV2> templates) {
    for (final tpl in templates) {
      tpl.meta['level'] = _detectLevel(tpl);
    }
    return templates;
  }

  int _detectLevel(TrainingPackTemplateV2 tpl) {
    final tags = {for (final t in tpl.tags) t.toLowerCase()};
    if (tags.contains('pushfold') ||
        tpl.trainingType == TrainingType.pushFold) {
      return 1;
    }
    if (tags.contains('open') || tags.contains('3betpush')) {
      return 2;
    }
    if (tags.contains('jamdecision') ||
        tpl.trainingType == TrainingType.postflop) {
      return 3;
    }
    return 0;
  }
}
