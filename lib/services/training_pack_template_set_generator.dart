import 'dart:convert';

import '../models/v2/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackTemplateV2]
/// instances by applying mustache-style interpolation for each variant.
class TrainingPackTemplateSetGenerator {
  const TrainingPackTemplateSetGenerator();

  /// Generates all packs defined by [set].
  List<TrainingPackTemplateV2> generate(TrainingPackTemplateSet set) {
    final baseJson = jsonEncode(set.template.toJson());
    final result = <TrainingPackTemplateV2>[];
    for (final variant in set.variants) {
      var json = baseJson;
      variant.forEach((key, value) {
        json = json.replaceAll('{{${key}}}', value.toString());
      });
      final map = jsonDecode(json) as Map<String, dynamic>;
      result.add(TrainingPackTemplateV2.fromJson(map));
    }
    return result;
  }

  /// Parses [yaml] and generates all packs from it.
  List<TrainingPackTemplateV2> generateFromYaml(String yaml) {
    final set = TrainingPackTemplateSet.fromYaml(yaml);
    return generate(set);
  }
}
