import '../models/v2/training_pack_template_v2.dart';
import '../core/training/generation/yaml_reader.dart';

class TrainingPackYamlCodecV2 {
  const TrainingPackYamlCodecV2();

  String encode(TrainingPackTemplateV2 template) => template.toYamlString();

  TrainingPackTemplateV2 decode(String yaml) {
    final map = const YamlReader().read(yaml);
    return TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  }
}
