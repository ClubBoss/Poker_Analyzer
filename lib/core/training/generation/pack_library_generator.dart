import 'pack_yaml_config_parser.dart';
import 'push_fold_pack_generator.dart';
import 'training_pack_generator_engine.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/training_pack_v2.dart';

class PackLibraryGenerator {
  final PackYamlConfigParser parser;
  final PushFoldPackGenerator generator;
  final TrainingPackGeneratorEngine engine;
  const PackLibraryGenerator({
    PackYamlConfigParser? yamlParser,
    PushFoldPackGenerator? pushFoldGenerator,
    TrainingPackGeneratorEngine? packEngine,
  })  : parser = yamlParser ?? const PackYamlConfigParser(),
        generator = pushFoldGenerator ?? const PushFoldPackGenerator(),
        engine = packEngine ?? const TrainingPackGeneratorEngine();

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

  Future<List<TrainingPackV2>> generateFromTemplates(
    List<TrainingPackTemplateV2> templates,
  ) async {
    final list = <TrainingPackV2>[];
    for (final t in templates) {
      if (t.spots.isEmpty) continue;
      if (t.meta['enabled'] == false) continue;
      final pack = await engine.generateFromTemplate(t);
      list.add(pack);
    }
    list.sort(
      (a, b) =>
          ((a.meta['priority'] as num?)?.toInt() ?? a.difficulty).compareTo(
        (b.meta['priority'] as num?)?.toInt() ?? b.difficulty,
      ),
    );
    return list;
  }
}
