import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/pack_generator_service.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/generate_pushfold_packs.dart <config.yaml>');
    exit(1);
  }
  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('Config not found: ${args.first}');
    exit(1);
  }
  final doc = loadYaml(file.readAsStringSync());
  if (doc is! YamlMap) {
    stderr.writeln('Invalid config');
    exit(1);
  }
  final outDir = Directory(doc['output']?.toString() ?? './out');
  outDir.createSync(recursive: true);
  final defaultAnte = (doc['defaultAnteBb'] as num?)?.toInt() ?? 0;
  final packs = doc['packs'];
  if (packs is! YamlList) {
    stderr.writeln('No packs defined');
    exit(1);
  }
  final total = packs.length;
  final start = DateTime.now();
  var index = 0;
  for (final item in packs) {
    index++;
    try {
      if (item is! YamlMap) throw 'Invalid pack';
      final id = item['id'].toString();
      final name = item['name'].toString();
      final heroBbStack = (item['heroBbStack'] as num).toInt();
      final playerStacksBb = [
        for (final v in item['playerStacksBb']) (v as num).toInt()
      ];
      final heroPos = parseHeroPosition(item['heroPos'].toString());
      final rangeRaw = item['heroRange'];
      List<String> heroRange;
      if (rangeRaw is YamlList) {
        heroRange = [for (final v in rangeRaw) v.toString()];
      } else if (rangeRaw is String) {
        final s = rangeRaw.trim();
        final top = RegExp(r'^top(\\d+)\\$').firstMatch(s);
        final topFun = RegExp(r'^topNHands\\((\\d+)\\)\\$').firstMatch(s);
        if (top != null) {
          heroRange =
              PackGeneratorService.topNHands(int.parse(top[1]!)).toList();
        } else if (topFun != null) {
          heroRange =
              PackGeneratorService.topNHands(int.parse(topFun[1]!)).toList();
        } else {
          heroRange = PackGeneratorService.parseRangeString(s).toList();
        }
      } else {
        heroRange = [];
      }
      final bbCallPct = (item['bbCallPct'] as num?)?.toInt() ?? 20;
      final anteBb = (item['anteBb'] as num?)?.toInt() ?? defaultAnte;
      final tpl = PackGeneratorService.generatePushFoldPackSync(
        id: id,
        name: name,
        heroBbStack: heroBbStack,
        playerStacksBb: playerStacksBb,
        heroPos: heroPos,
        heroRange: heroRange,
        anteBb: anteBb,
        bbCallPct: bbCallPct,
      );
      final issues = validateTrainingPackTemplate(tpl);
      if (issues.isNotEmpty) throw issues.join('; ');
      final jsonPath = p.join(outDir.path, '$id.json');
      File(jsonPath).writeAsStringSync(jsonEncode(tpl.toJson()));
      final csvPath = p.join(outDir.path, '$id.csv');
      File(csvPath).writeAsStringSync(_tplToCsv(tpl));
      stdout.writeln('[$index/$total] $id - ${tpl.spots.length} spots - OK');
    } catch (e) {
      stderr.writeln(
          '[$index/$total] ${item is YamlMap ? item['id'] : ''} - [ERROR] $e');
    }
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds / 1000;
  stdout.writeln('Done in ${elapsed.toStringAsFixed(1)} s');
}

String _tplToCsv(tpl) {
  final rows = <List<dynamic>>[
    [
      'Title',
      'HeroPosition',
      'HeroHand',
      'StackBB',
      'StacksBB',
      'HeroIndex',
      'CallsMask',
      'EV_BB',
      'ICM_EV',
      'Tags'
    ],
  ];
  for (final spot in tpl.spots) {
    final hand = spot.hand;
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++)
        hand.stacks['$i']?.toString() ?? ''
    ].join('/');
    final pre = hand.actions[0] ?? [];
    final callsMask = hand.playerCount == 2
        ? ''
        : [
            for (var i = 0; i < hand.playerCount; i++)
              pre.any((a) => a.playerIndex == i && a.action == 'call')
                  ? '1'
                  : '0'
          ].join();
    rows.add([
      spot.title,
      hand.position.label,
      hand.heroCards,
      hand.stacks['${hand.heroIndex}']?.toString() ?? '',
      stacks,
      hand.heroIndex,
      callsMask,
      spot.heroEv?.toStringAsFixed(1) ?? '',
      spot.heroIcmEv?.toStringAsFixed(3) ?? '',
      spot.tags.join('|'),
    ]);
  }
  return const ListToCsvConverter().convert(rows);
}
