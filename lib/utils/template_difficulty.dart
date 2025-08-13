import '../models/training_pack_template_model.dart';
import '../models/v2/training_pack_template.dart' as legacy;
import '../models/v2/training_pack_template_v2.dart' as v2;

extension TemplateDifficulty on Object {
  int get difficultyLevel {
    if (this is TrainingPackTemplateModel) {
      return (this as TrainingPackTemplateModel).difficulty;
    }
    if (this is legacy.TrainingPackTemplate) {
      return int.tryParse(
              (this as legacy.TrainingPackTemplate).difficulty ?? '') ??
          0;
    }
    if (this is v2.TrainingPackTemplateV2) {
      final diff = (this as v2.TrainingPackTemplateV2).meta['difficulty'];
      if (diff is int) return diff;
      if (diff is String) return int.tryParse(diff) ?? 0;
      return 0;
    }
    return 0;
  }
}
