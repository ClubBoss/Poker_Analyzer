import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'l3_presets.dart';

const _ranks = [
  'A',
  'K',
  'Q',
  'J',
  'T',
  '9',
  '8',
  '7',
  '6',
  '5',
  '4',
  '3',
  '2',
];
const _suits = ['s', 'h', 'd', 'c'];

List<String> _buildDeck() {
  return [
    for (final r in _ranks)
      for (final s in _suits) '$r$s',
  ];
}

List<String> _generateBoard(Random rng) {
  final deck = _buildDeck();
  List<String> cards = [];
  for (var i = 0; i < 5; i++) {
    final c = deck.removeAt(rng.nextInt(deck.length));
    cards.add(c);
  }
  return cards;
}

String _texture(List<String> flop) {
  final suits = flop.map((c) => c[1]).toSet();
  if (suits.length == 1) return 'monotone';
  if (suits.length == 2) return 'twoTone';
  return 'rainbow';
}

bool _isPaired(List<String> flop) {
  final ranks = flop.map((c) => c[0]).toList();
  return ranks[0] == ranks[1] || ranks[0] == ranks[2] || ranks[1] == ranks[2];
}

bool _isAceHigh(List<String> flop) => flop.any((c) => c[0] == 'A');

bool _isBroadway(List<String> flop) {
  const broadway = {'A', 'K', 'Q', 'J', 'T'};
  return flop.where((c) => broadway.contains(c[0])).length >= 2;
}

Map<String, double> _parseTargetMix(String arg) {
  final file = File(arg);
  final content = file.existsSync() ? file.readAsStringSync() : arg;
  final decoded = json.decode(content) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
}

Map<String, int> _allocateCounts(Map<String, double> mix, int total) {
  final counts = <String, int>{};
  var remaining = total;
  final entries = mix.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    final key = entries[i].key;
    int count;
    if (i == entries.length - 1) {
      count = remaining;
    } else {
      count = (entries[i].value * total).round();
      remaining -= count;
    }
    counts[key] = count;
  }
  return counts;
}

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('preset', defaultsTo: 'all')
    ..addOption('seed', defaultsTo: '42')
    ..addOption('out', defaultsTo: 'build/tmp/l3')
    ..addOption('targetMix');
  final res = parser.parse(args);
  final presetArg = res['preset'] as String;
  final seed = int.parse(res['seed'] as String);
  final outDir = res['out'] as String;
  final targetMixArg = res['targetMix'] as String?;

  final presets = presetArg == 'all' ? allPresets : [presetArg];

  final rng = Random(seed);

  for (final name in presets) {
    final preset = l3Presets[name];
    if (preset == null) {
      stderr.writeln('Unknown preset $name');
      exit(1);
    }
    final mix =
        targetMixArg != null ? _parseTargetMix(targetMixArg) : preset.targetMix;
    _generateForPreset(outDir, name, preset, rng, mix);
  }
}

void _generateForPreset(
  String outDir,
  String name,
  L3Preset preset,
  Random rng,
  Map<String, double> mix,
) {
  const spotCount = 100;
  final counts = _allocateCounts(mix, spotCount);
  final boards = <String>[];
  final textures = <String>[];
  final used = <String>{};

  for (final entry in counts.entries) {
    final texture = entry.key;
    final count = entry.value;
    for (var i = 0; i < count; i++) {
      while (true) {
        final board = _generateBoard(rng);
        final flop = board.sublist(0, 3);
        if (_texture(flop) != texture) continue;
        if (preset.filter != null && !preset.filter!(flop)) continue;
        final boardStr = board.join();
        if (used.add(boardStr)) {
          boards.add(boardStr);
          textures.add(texture);
          break;
        }
      }
    }
  }

  final dir = Directory(p.join(outDir, 'postflop-jam', name));
  dir.createSync(recursive: true);
  final id = 'l3-postflop-jam-$name';
  final file = File(p.join(dir.path, '$id.yaml'));
  final sb = StringBuffer();
  sb.writeln('id: $id');
  sb.writeln('stage:');
  sb.writeln('  id: L3');
  sb.writeln('subtype: postflop-jam');
  sb.writeln('street: flop');
  sb.writeln('tags:');
  sb.writeln('  - l3');
  sb.writeln('  - $name');
  sb.writeln('spots:');
  for (var i = 0; i < boards.length; i++) {
    final spotId = '${id}-s${(i + 1).toString().padLeft(3, '0')}';
    final board = boards[i];
    final flop = [
      board.substring(0, 2),
      board.substring(2, 4),
      board.substring(4, 6),
    ];
    final texture = textures[i];
    final tags = <String>['l3', texture];
    tags.add(_isPaired(flop) ? 'paired' : 'unpaired');
    if (_isAceHigh(flop)) tags.add('ace-high');
    if (_isBroadway(flop)) tags.add('broadway');
    sb.writeln('  -');
    sb.writeln('    id: $spotId');
    sb.writeln('    actionType: postflop-jam');
    sb.writeln('    board: $board');
    sb.writeln('    tags:');
    for (final t in tags) {
      sb.writeln('      - $t');
    }
  }
  file.writeAsStringSync(sb.toString());
}
