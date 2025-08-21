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

final Map<String, List<List<String>>> _allFlopsByTexture =
    _computeAllFlopsByTexture();

Map<String, List<List<String>>> _computeAllFlopsByTexture() {
  final deck = _buildDeck();
  final res = {
    'monotone': <List<String>>[],
    'twoTone': <List<String>>[],
    'rainbow': <List<String>>[],
  };
  for (var i = 0; i < deck.length; i++) {
    for (var j = i + 1; j < deck.length; j++) {
      for (var k = j + 1; k < deck.length; k++) {
        final flop = [deck[i], deck[j], deck[k]];
        res[_texture(flop)]!.add(flop);
      }
    }
  }
  for (final list in res.values) {
    list.sort((a, b) => a.join().compareTo(b.join()));
  }
  return res;
}

class _Spot {
  final String board;
  final String texture;

  _Spot(this.board, this.texture);
}

const _neighbors = {
  'monotone': ['twoTone', 'rainbow'],
  'twoTone': ['monotone', 'rainbow'],
  'rainbow': ['twoTone', 'monotone'],
};

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('preset', defaultsTo: 'all')
    ..addOption('seed', defaultsTo: '42')
    ..addOption('out', defaultsTo: 'build/tmp/l3')
    ..addOption('targetMix')
    ..addOption('timeoutSec', defaultsTo: '90')
    ..addOption('maxAttemptsPerSpot', defaultsTo: '5000')
    ..addOption('dedupe', defaultsTo: 'flop', allowed: ['flop', 'board']);
  final res = parser.parse(args);
  final presetArg = res['preset'] as String;
  final seed = int.parse(res['seed'] as String);
  final outDir = res['out'] as String;
  final targetMixArg = res['targetMix'] as String?;
  final timeout = Duration(seconds: int.parse(res['timeoutSec'] as String));
  final maxAttempts = int.parse(res['maxAttemptsPerSpot'] as String);
  final dedupe = res['dedupe'] as String;

  final presets = presetArg == 'all' ? allPresets : [presetArg];

  final rng = Random(seed);
  final start = DateTime.now();

  for (final name in presets) {
    final preset = l3Presets[name];
    if (preset == null) {
      stderr.writeln('Unknown preset $name');
      exit(1);
    }
    final mix =
        targetMixArg != null ? _parseTargetMix(targetMixArg) : preset.targetMix;
    _generateForPreset(
      outDir,
      name,
      preset,
      rng,
      mix,
      timeout,
      maxAttempts,
      dedupe,
      start,
    );
  }
}

void _generateForPreset(
  String outDir,
  String name,
  L3Preset preset,
  Random rng,
  Map<String, double> mix,
  Duration timeout,
  int maxAttempts,
  String dedupe,
  DateTime start,
) {
  const spotCount = 100;
  final counts = _allocateCounts(mix, spotCount);

  final flopsByTexture = {
    for (final e in _allFlopsByTexture.entries)
      e.key: e.value
          .where((f) => preset.filter == null || preset.filter!(f))
          .map((f) => List<String>.from(f))
          .toList(),
  };

  final available = {
    for (final e in flopsByTexture.entries) e.key: e.value.length,
  };

  final actual = <String, int>{
    for (final e in counts.entries) e.key: min(e.value, available[e.key] ?? 0),
  };

  final shortages = <String, int>{};
  for (final key in counts.keys) {
    final need = counts[key]!;
    final have = actual[key]!;
    if (have < need) shortages[key] = need - have;
  }

  final totalSoFar = actual.values.fold<int>(0, (a, b) => a + b);
  var remaining = spotCount - totalSoFar;
  for (final entry in shortages.entries) {
    var need = entry.value;
    for (final n in _neighbors[entry.key]!) {
      if (remaining <= 0) break;
      final avail = available[n]! - (actual[n] ?? 0);
      if (avail <= 0) continue;
      final take = min(need, min(avail, remaining));
      if (take > 0) {
        actual[n] = (actual[n] ?? 0) + take;
        remaining -= take;
        need -= take;
        stdout.writeln(
          '::warning::${name} borrowed $take from $n for ${entry.key}',
        );
      }
      if (need == 0) break;
    }
  }

  if (actual.values.fold<int>(0, (a, b) => a + b) != spotCount) {
    stderr.writeln('Unable to fill $spotCount spots for $name');
    exit(1);
  }

  final usedBoards = <String>{};
  final usedFlops = dedupe == 'flop' ? <String>{} : null;
  final spots = <_Spot>[];

  for (final texture in ['monotone', 'twoTone', 'rainbow']) {
    final need = actual[texture] ?? 0;
    if (need == 0) continue;
    final flops = flopsByTexture[texture]!;
    flops.shuffle(rng);
    var idx = 0;
    while (spots.where((s) => s.texture == texture).length < need) {
      if (DateTime.now().difference(start) > timeout) {
        stderr.writeln('Timeout generating boards for $name');
        exit(1);
      }
      if (idx >= flops.length) {
        stderr.writeln('Insufficient flops for $texture in $name');
        exit(1);
      }
      final flop = flops[idx++];
      final flopStr = flop.join();
      if (usedFlops != null && !usedFlops.add(flopStr)) {
        continue;
      }
      var attempts = 0;
      while (true) {
        if (DateTime.now().difference(start) > timeout) {
          stderr.writeln('Timeout generating boards for $name');
          exit(1);
        }
        if (attempts++ >= maxAttempts) {
          stderr.writeln('Max attempts exceeded for spot in $name');
          exit(1);
        }
        final deck = _buildDeck();
        deck.removeWhere((c) => flop.contains(c));
        deck.shuffle(rng);
        final board = [...flop, deck[0], deck[1]];
        final boardStr = board.join();
        if (usedBoards.add(boardStr)) {
          spots.add(_Spot(boardStr, texture));
          break;
        }
      }
    }
  }

  spots.sort((a, b) => a.board.compareTo(b.board));

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
  for (var i = 0; i < spots.length; i++) {
    final spotId = '${id}-s${(i + 1).toString().padLeft(3, '0')}';
    final board = spots[i].board;
    final flop = [
      board.substring(0, 2),
      board.substring(2, 4),
      board.substring(4, 6),
    ];
    final texture = spots[i].texture;
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
