import 'pack_yaml_config_parser.dart';
import 'push_fold_pack_generator.dart';
import 'training_pack_generator_engine.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/training_pack_v2.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/hero_position.dart';
import '../engine/training_type_engine.dart';

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

  List<String> autoTags(TrainingPackTemplate template) {
    final set = <String>{};
    final positions = <HeroPosition>{template.heroPos};
    var maxPlayers = 0;
    final stacks = <int>{};
    var maxStack = 0;
    var minStack = 1 << 20;
    var flop = false;
    var turn = false;
    var river = false;
    for (final s in template.spots) {
      positions.add(s.hand.position);
      maxPlayers =
          s.hand.playerCount > maxPlayers ? s.hand.playerCount : maxPlayers;
      final st = s.hand.stacks['${s.hand.heroIndex}']?.round();
      if (st != null) {
        stacks.add(st);
        if (st > maxStack) maxStack = st;
        if (st < minStack) minStack = st;
      }
      final len = s.hand.board.length;
      if (len >= 3) flop = true;
      if (len >= 4) turn = true;
      if (len >= 5) river = true;
    }
    for (final p in positions) {
      if (p != HeroPosition.unknown) set.add(p.name.toUpperCase());
    }
    if (maxPlayers <= 2) {
      set.add('HU');
    } else if (maxPlayers == 3) {
      set.add('3way');
    } else {
      set.add('4way+');
    }
    for (final st in stacks) {
      set.add('${st}bb');
    }
    if (minStack <= 10) set.add('short');
    if (maxStack >= 40) set.add('deep');
    if (flop) set.add('flop');
    if (turn) set.add('turn');
    if (river) set.add('river');
    final list = set.toList();
    list.sort();
    return list;
  }

  List<String> _autoTagsV2(TrainingPackTemplateV2 t) {
    final tmp = TrainingPackTemplate(
      id: t.id,
      name: t.name,
      spots: [for (final s in t.spots) TrainingPackSpot.fromJson(s.toJson())],
      heroPos: t.positions.isNotEmpty
          ? parseHeroPosition(t.positions.first)
          : HeroPosition.unknown,
      heroBbStack: t.bb,
    );
    return autoTags(tmp);
  }

  String generateTitle(TrainingPackTemplate template,
      [TrainingType type = TrainingType.pushfold]) {
    final pos = template.heroPos.label;
    final bb = template.heroBbStack;
    final game = template.gameType.label;
    if (type == TrainingType.pushfold) {
      return '$pos Push ${bb}bb ($game)';
    }
    final stack = bb >= 40 ? 'DeepStack Pack' : '${bb}bb Pack';
    return '$pos $stack';
  }

  String _generateTitleV2(TrainingPackTemplateV2 t) {
    final pos = t.positions.isNotEmpty
        ? parseHeroPosition(t.positions.first).label
        : HeroPosition.unknown.label;
    final bb = t.bb;
    final game = t.gameType.label;
    if (t.type == TrainingType.pushfold) {
      return '$pos Push ${bb}bb ($game)';
    }
    final stack = bb >= 40 ? 'DeepStack Pack' : '${bb}bb Pack';
    return '$pos $stack';
  }

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
      if (r.title.isNotEmpty) {
        tpl.name = r.title;
      } else {
        tpl.name = generateTitle(tpl);
      }
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
      tpl.tags = {...tpl.tags, ...autoTags(tpl)}.toList();
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
      if (t.name.isEmpty) {
        t.name = _generateTitleV2(t);
      }
      t.meta['difficulty'] = estimateDifficultyV2(t);
      t.tags = {...t.tags, ..._autoTagsV2(t)}.toList();
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
