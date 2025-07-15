import 'pack_yaml_config_parser.dart';
import 'pack_generation_request.dart';
import 'push_fold_pack_generator.dart';
import '../../../models/v2/training_pack_template.dart';

class PackLibraryGenerator {
  final PackYamlConfigParser parser;
  final PushFoldPackGenerator generator;
  const PackLibraryGenerator({
    PackYamlConfigParser? yamlParser,
    PushFoldPackGenerator? pushFoldGenerator,
  })  : parser = yamlParser ?? const PackYamlConfigParser(),
        generator = pushFoldGenerator ?? const PushFoldPackGenerator();

  List<TrainingPackTemplate> generateFromYaml(String yaml) {
    final requests = parser.parse(yaml);
    final list = <TrainingPackTemplate>[];
    for (final r in requests) {
      final tpl = generator.generate(
        gameType: r.gameType,
        bb: r.bb,
        positions: r.positions,
      );
      if (r.title.isNotEmpty) tpl.name = r.title;
      if (r.description.isNotEmpty) tpl.description = r.description;
      if (r.tags.isNotEmpty) tpl.tags = List<String>.from(r.tags);
      tpl.spotCount = tpl.spots.length;
      list.add(tpl);
    }
    return list;
  }
}
