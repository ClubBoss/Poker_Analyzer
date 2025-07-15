import 'pack_yaml_config_parser.dart';
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
    final config = parser.parse(yaml);
    final requests = config.requests;
    final list = <TrainingPackTemplate>[];
    for (final r in requests) {
      final tpl = generator.generate(
        gameType: r.gameType,
        bb: r.bb,
        bbList: r.bbList,
        positions: r.positions,
        count: r.count,
        rangeGroup: r.rangeGroup,
        multiplePositions: r.multiplePositions,
      );
      if (r.title.isNotEmpty) tpl.name = r.title;
      if (r.description.isNotEmpty) tpl.description = r.description;
      final tags = List<String>.from(r.tags);
      if (config.rangeTags &&
          r.rangeGroup != null &&
          r.rangeGroup!.isNotEmpty &&
          !tags.contains(r.rangeGroup)) {
        tags.add(r.rangeGroup!);
      }
      if (tags.isNotEmpty) tpl.tags = tags;
      tpl.spotCount = tpl.spots.length;
      list.add(tpl);
    }
    return list;
  }
}
