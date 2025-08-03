import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_template_set.dart';
import '../core/training/generation/yaml_reader.dart';

class TrainingPackYamlCodecV2 {
  const TrainingPackYamlCodecV2();

  String encode(TrainingPackTemplateV2 template) => template.toYamlString();

  TrainingPackTemplateV2 decode(String yaml) {
    final map = const YamlReader().read(yaml);
    return TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  }

  /// Decodes [yaml] that may contain a single template or a `templateSet`.
  /// Returns all resulting templates.
  List<TrainingPackTemplateV2> decodeMany(String yaml) {
    final map = const YamlReader().read(yaml);
    if (map['templateSet'] is Map) {
      final set = TrainingPackTemplateSet.fromJson(
        Map<String, dynamic>.from(map['templateSet'] as Map),
      );
      return set.generateAllPacks();
    }
    return [TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map))];
  }
}
