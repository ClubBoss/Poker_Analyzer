import 'pack_yaml_config_parser.dart';
import 'push_fold_pack_generator.dart';
import 'training_pack_generator_engine.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/training_pack_v2.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/hero_position.dart';

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

  int _estimateDifficultyFromSpots(List<TrainingPackSpot> spots) {
    var diff = 1;
    final streets = <int>{};
    final positions = <HeroPosition>{};
    var customStack = false;
    for (final s in spots) {
      streets.add(s.street);
      positions.add(s.hand.position);
      final stack = s.hand.stacks['${s.hand.heroIndex}']?.round();
      if (stack != null && stack != 10 && stack != 20) customStack = true;
    }
    if (streets.length >= 3) diff++;
    if (positions.length >= 3) diff++;
    if (customStack) diff++;
    if (diff > 3) diff = 3;
    return diff;
  }

  int estimateDifficulty(TrainingPackTemplate template) =>
      _estimateDifficultyFromSpots(template.spots);

  int estimateDifficultyV2(TrainingPackTemplateV2 template) =>
      _estimateDifficultyFromSpots(template.spots);

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
      tpl.meta['difficulty'] = estimateDifficulty(tpl);
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
      t.meta['difficulty'] = estimateDifficultyV2(t);
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
