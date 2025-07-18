import 'package:flutter/services.dart' show rootBundle;
import '../generation/pack_yaml_config_parser.dart';
import '../generation/pack_library_generator.dart';
import '../engine/training_type_engine.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/training_pack_v2.dart';

class BuiltInPackSeeder {
  const BuiltInPackSeeder();

  Future<List<TrainingPackV2>> loadBuiltInLibrary() async {
    final yaml = await rootBundle.loadString('assets/built_in_packs.yaml');
    final config = const PackYamlConfigParser().parse(yaml);
    final typeEngine = TrainingTypeEngine();
    final templates = <TrainingPackTemplateV2>[];
    for (final r in config.requests) {
      final t = await typeEngine.build(TrainingType.pushFold, r);
      if (config.rangeTags &&
          r.rangeGroup != null &&
          r.rangeGroup!.isNotEmpty &&
          !t.tags.contains(r.rangeGroup)) {
        t.tags = List<String>.from(t.tags)..add(r.rangeGroup!);
      }
      templates.add(t);
    }
    if (templates.isEmpty) return [];
    return const PackLibraryGenerator().generateFromTemplates(templates);
  }
}
