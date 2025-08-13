import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/helpers/training_pack_validator.dart';
import 'package:poker_analyzer/services/push_fold_ev_service.dart';

Future<void> main(List<String> args) async {
  String? input;
  String? output;
  for (final a in args) {
    if (a.startsWith('--input=')) input = a.substring(8);
    if (a.startsWith('--output=')) output = a.substring(9);
  }
  if (input == null || output == null) {
    stderr.writeln(
        'Usage: dart run tool/generate_pack.dart --input=spots.json --output=pack.yaml');
    exit(1);
  }
  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('Input not found: $input');
    exit(1);
  }
  List list;
  try {
    final data = jsonDecode(file.readAsStringSync());
    if (data is! List) throw 'Not a list';
    list = data;
  } catch (e) {
    stderr.writeln('Invalid JSON');
    exit(1);
  }
  final spots = <TrainingPackSpot>[];
  const evService = PushFoldEvService();
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is! Map) {
      stderr.writeln('Invalid spot at ${i + 1}');
      exit(1);
    }
    final title = item['title']?.toString();
    final posStr = item['heroPos']?.toString();
    final stack = (item['stackBB'] as num?)?.toInt();
    final handStr = item['heroRange']?.toString();
    final action = item['action']?.toString();
    if ([title, posStr, stack, handStr, action].contains(null)) {
      stderr.writeln('Missing fields in spot ${i + 1}');
      exit(1);
    }
    final pos = parseHeroPosition(posStr!);
    final cards = _firstCombo(handStr!);
    final hand = HandData.fromSimpleInput(cards, pos, stack!);
    if (action == 'fold') {
      hand.actions = {
        0: [ActionEntry(0, 0, 'fold')]
      };
    }
    final spot = TrainingPackSpot(
      id: 's${i + 1}',
      title: title!,
      hand: hand,
      tags: const ['pushfold'],
    );
    await evService.evaluate(spot);
    await evService.evaluateIcm(spot);
    spots.add(spot);
  }
  if (spots.isEmpty) {
    stderr.writeln('No spots');
    exit(1);
  }
  final first = spots.first.hand;
  final tpl = TrainingPackTemplate(
    id: p.basenameWithoutExtension(output),
    name: p.basenameWithoutExtension(output),
    gameType: GameType.tournament,
    spots: spots,
    heroBbStack: first.stacks['0']?.round() ?? 0,
    playerStacksBb: [
      for (var i = 0; i < first.playerCount; i++)
        first.stacks['$i']?.round() ?? 0
    ],
    heroPos: first.position,
  );
  final issues = validateTrainingPackTemplate(tpl);
  if (issues.isNotEmpty) {
    stderr.writeln('Invalid pack: ${issues.join('; ')}');
    exit(1);
  }
  final outPath = p.join('assets', 'packs', output);
  File(outPath).createSync(recursive: true);
  File(outPath).writeAsStringSync(const YamlEncoder().convert(tpl.toJson()));
  stdout.writeln('Pack generated: $outPath');
}

String _firstCombo(String hand) {
  const suits = ['h', 'd', 'c', 's'];
  final h = hand.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (h.length == 2) {
    final r = h[0];
    return '$r${suits[0]} $r${suits[1]}';
  }
  final r1 = h[0];
  final r2 = h[1];
  final suited = h.length > 2 && h[2] == 'S';
  if (suited) return '$r1${suits[0]} $r2${suits[0]}';
  return '$r1${suits[0]} $r2${suits[1]}';
}
