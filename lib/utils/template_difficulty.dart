import '../models/training_pack_template_model.dart';
import '../models/v2/training_pack_template.dart' as v2;

extension TemplateDifficulty on Object {
  int get difficultyLevel {
    if (this is TrainingPackTemplateModel) {
      return (this as TrainingPackTemplateModel).difficulty;
    }
    if (this is v2.TrainingPackTemplate) {
      return int.tryParse((this as v2.TrainingPackTemplate).difficulty ?? '') ?? 0;
    }
    return 0;
  }
}
