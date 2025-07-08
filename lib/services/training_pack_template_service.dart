import '../models/v2/training_pack_preset.dart';
import '../models/v2/training_pack_template.dart';
import 'pack_generator_service.dart';

class TrainingPackTemplateService {
  static Future<TrainingPackTemplate> generateFromPreset(
      TrainingPackPreset preset) {
    return PackGeneratorService.generatePackFromPreset(preset);
  }
}
