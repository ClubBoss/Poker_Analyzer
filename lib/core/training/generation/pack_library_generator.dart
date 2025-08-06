import 'dart:developer' as developer;

import 'pack_yaml_config_parser.dart';
import 'push_fold_pack_generator.dart';
import 'training_pack_generator_engine.dart';
import 'training_pack_source_tagger.dart';
import 'training_pack_tags_engine.dart';
import '../../../models/v2/training_pack_template.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/training_pack_v2.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/hero_position.dart';
import '../engine/training_type_engine.dart';
import '../../../services/level_tag_auto_assigner.dart';

class PackLibraryGenerator {
  final PackYamlConfigParser parser;
  final PushFoldPackGenerator generator;
  final TrainingPackGeneratorEngine engine;
  final TrainingPackSourceTagger tagger;
  final TrainingPackTagsEngine tagsEngine;
  final LevelTagAutoAssigner levelAssigner;
  const PackLibraryGenerator({
    PackYamlConfigParser? yamlParser,
    PushFoldPackGenerator? pushFoldGenerator,
    TrainingPackGeneratorEngine? packEngine,
    TrainingPackSourceTagger? sourceTagger,
    TrainingPackTagsEngine? tagsEngine,
    LevelTagAutoAssigner? levelAssigner,
  }) : parser = yamlParser ?? const PackYamlConfigParser(),
       generator = pushFoldGenerator ?? const PushFoldPackGenerator(),
       engine = packEngine ?? const TrainingPackGeneratorEngine(),
       tagger = sourceTagger ?? const TrainingPackSourceTagger(),
       tagsEngine = tagsEngine ?? const TrainingPackTagsEngine(),
       levelAssigner = levelAssigner ?? const LevelTagAutoAssigner();

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
      maxPlayers = s.hand.playerCount > maxPlayers
          ? s.hand.playerCount
          : maxPlayers;
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

  String generateTitle(
    TrainingPackTemplate template, [
    TrainingType type = TrainingType.pushFold,
  ]) {
    final pos = template.heroPos.label;
    final bb = template.heroBbStack;
    final game = template.gameType.label;
    if (type == TrainingType.pushFold) {
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
    if (t.trainingType == TrainingType.pushFold) {
      return '$pos Push ${bb}bb ($game)';
    }
    final stack = bb >= 40 ? 'DeepStack Pack' : '${bb}bb Pack';
    return '$pos $stack';
  }

  String generateDescription(TrainingPackTemplate t) {
    final pos = t.heroPos.label;
    final bb = t.heroBbStack;
    final game = t.gameType.label.toLowerCase();
    final count = t.spotCount > 0 ? t.spotCount : t.spots.length;
    var players = 0;
    var street = 0;
    for (final s in t.spots) {
      if (s.hand.playerCount > players) players = s.hand.playerCount;
      if (s.hand.board.length > street) street = s.hand.board.length;
    }
    final stackLabel = bb >= 40 ? '${bb}bb+' : '${bb}bb';
    final playerText = players <= 2
        ? 'heads-up'
        : players == 3
        ? '3 players'
        : '3+ players';
    final streetText = street >= 5
        ? 'river'
        : street == 4
        ? 'turn'
        : street == 3
        ? 'flop'
        : 'preflop';
    final push = t.tags.any((e) => e.toLowerCase().contains('push'));
    final base = push
        ? 'Push/Fold training from $pos with $stackLabel'
        : '${streetText[0].toUpperCase()}${streetText.substring(1)} spots for $pos $stackLabel vs $playerText';
    return '$base in $game - $count spots';
  }

  String _generateDescriptionV2(TrainingPackTemplateV2 t) {
    final tmp = TrainingPackTemplate(
      id: t.id,
      name: t.name,
      spots: [for (final s in t.spots) TrainingPackSpot.fromJson(s.toJson())],
      heroPos: t.positions.isNotEmpty
          ? parseHeroPosition(t.positions.first)
          : HeroPosition.unknown,
      heroBbStack: t.bb,
      gameType: t.gameType,
    );
    tmp.spotCount = t.spotCount;
    tmp.tags = List<String>.from(t.tags);
    return generateDescription(tmp);
  }

  int _estimateDifficultyFromSpots(List<TrainingPackSpot> spots) {
    final streets = <int>{};
    final positions = <HeroPosition>{};
    var customStack = false;
    for (final s in spots) {
      streets.add(s.street);
      positions.add(s.hand.position);
      final stack = s.hand.stacks['${s.hand.heroIndex}']?.round();
      if (stack != null && stack != 10 && stack != 20) customStack = true;
    }
    if (streets.length >= 3 || positions.length >= 3 || customStack) {
      return 3;
    }
    if (streets.length > 1 || positions.length > 1) {
      return 2;
    }
    return 1;
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
      tagger.tag(
        TrainingPackTemplateV2.fromTemplate(tpl, type: TrainingType.pushFold),
        source: PackSource.yaml.name,
      );
      tpl.meta['source'] ??= PackSource.yaml.name;
      if (r.recommended) {
        tpl.recommended = true;
        tpl.meta['recommended'] = true;
      }
      if (r.title.isNotEmpty) {
        tpl.name = r.title;
      } else {
        tpl.name = generateTitle(tpl);
      }
      if (r.description.isNotEmpty) tpl.description = r.description;
      if (r.goal.isNotEmpty) tpl.goal = r.goal;
      if (r.audience.isNotEmpty) tpl.meta['audience'] = r.audience;
      final tags = List<String>.from(r.tags);
      if (config.rangeTags &&
          r.rangeGroup != null &&
          r.rangeGroup!.isNotEmpty &&
          !tags.contains(r.rangeGroup)) {
        tags.add(r.rangeGroup!);
      }
      if (tags.isNotEmpty) tpl.tags = tags;
      final tV2 = TrainingPackTemplateV2.fromTemplate(
        tpl,
        type: TrainingType.pushFold,
      );
      final autoTagList = tagsEngine.generate(tV2);
      tpl.spotCount = tpl.spots.length;
      if (tpl.meta['difficulty'] is! int) {
        tpl.meta['difficulty'] = estimateDifficulty(tpl);
      }
      tpl.tags = {...tpl.tags, ...autoTags(tpl), ...autoTagList}.toList();
      if (tpl.description.isEmpty) {
        tpl.description = generateDescription(tpl);
      }
      if (tpl.goal.isEmpty) {
        tpl.goal = generateDescription(tpl);
      }
      tpl.meta['goal'] = tpl.goal;
      list.add(tpl);
    }
    return list;
  }

  Future<List<TrainingPackV2>> generateFromTemplates(
    List<TrainingPackTemplateV2> templates,
  ) async {
    final list = <TrainingPackV2>[];
    final assigned = levelAssigner.assign(templates);
    for (final t in assigned) {
      developer.log('Assigned level ${t.meta['level']} to ${t.id}');
      tagger.tag(t, source: PackSource.auto.name);
      if (t.spots.isEmpty) continue;
      if (t.meta['enabled'] == false) continue;
      if (t.recommended) t.meta['recommended'] = true;
      if (t.name.isEmpty) {
        t.name = _generateTitleV2(t);
      }
      if (t.meta['difficulty'] is! int) {
        t.meta['difficulty'] = estimateDifficultyV2(t);
      }
      if (t.audience != null && t.audience!.isNotEmpty) {
        t.meta['audience'] = t.audience;
      }
      t.tags = {
        ...t.tags,
        ..._autoTagsV2(t),
        ...tagsEngine.generate(t),
      }.toList();
      if (t.description.isEmpty) {
        t.description = _generateDescriptionV2(t);
      }
      if (t.goal.isEmpty) {
        t.goal = _generateDescriptionV2(t);
      }
      t.meta['goal'] = t.goal;
      final pack = await engine.generateFromTemplate(t);
      list.add(pack);
    }
    list.sort(
      (a, b) => ((a.meta['priority'] as num?)?.toInt() ?? a.difficulty)
          .compareTo((b.meta['priority'] as num?)?.toInt() ?? b.difficulty),
    );
    return list;
  }
}
