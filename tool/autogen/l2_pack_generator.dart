import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'l2_presets.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('preset', defaultsTo: 'all')
    ..addOption('seed', defaultsTo: '42')
    ..addOption('out', defaultsTo: 'build/tmp/l2_smoke');
  final argResults = parser.parse(args);
  final seed = int.parse(argResults['seed'] as String);
  final presetArg = argResults['preset'] as String;
  final outDir = argResults['out'] as String;

  final presetsToRun = presetArg == 'all' ? allPresets : [presetArg];
  final rng = Random(seed);

  var hadEmpty = false;
  for (final name in presetsToRun) {
    final preset = l2Presets[name];
    if (preset == null) {
      stderr.writeln('Unknown preset $name');
      exit(1);
    }
    switch (preset.subtype) {
      case 'open-fold':
        hadEmpty |= generateOpenFold(rng, outDir, preset);
        break;
      case '3bet-push':
        hadEmpty |= generate3betPush(rng, outDir, preset);
        break;
      case 'limped':
        hadEmpty |= generateLimped(rng, outDir, preset);
        break;
    }
  }

  if (hadEmpty) exit(1);
}

final _cards = [
  'AsAh',
  'AdAc',
  'KsKh',
  'KdKc',
  'QsQh',
  'QdQc',
  'JsJh',
  'JdJc',
  'TsTh',
  'TdTc',
];

String _spotAction(String subtype, int i) {
  switch (subtype) {
    case 'open-fold':
      return i.isEven ? 'open' : 'fold';
    case '3bet-push':
      return i.isEven ? 'push' : 'fold';
    case 'limped':
      return i.isEven ? 'check' : 'raise';
    default:
      return 'fold';
  }
}

int _writePack({
  required String path,
  required String id,
  required String name,
  required String subtype,
  required List<String> tags,
  String? position,
  String? stackBucket,
  bool limped = false,
  String? unlockAfter,
}) {
  final file = File(path);
  file.createSync(recursive: true);
  final sb = StringBuffer();
  sb.writeln('id: $id');
  sb.writeln('name: $name');
  sb.writeln('stage:');
  sb.writeln('  id: L2');
  if (unlockAfter != null) {
    sb.writeln('  unlockAfter: $unlockAfter');
  }
  sb.writeln('subtype: $subtype');
  if (position != null) sb.writeln('position: $position');
  if (stackBucket != null) sb.writeln('stackBucket: $stackBucket');
  if (limped) sb.writeln('limped: true');
  sb.writeln('objective: Decide the correct action');
  sb.writeln('tags:');
  for (final t in tags) {
    sb.writeln('  - $t');
  }
  sb.writeln('spots:');
  const spotCount = 80;
  for (var i = 0; i < spotCount; i++) {
    final card = _cards[i % _cards.length];
    final action = _spotAction(subtype, i);
    final spotId = '${id}-s${(i + 1).toString().padLeft(3, '0')}';
    sb.writeln('  -');
    sb.writeln('    id: $spotId');
    sb.writeln('    actionType: $subtype');
    sb.writeln('    heroCards: $card');
    sb.writeln('    correctAction: $action');
  }
  file.writeAsStringSync(sb.toString());
  return spotCount;
}

bool generateOpenFold(Random rng, String outDir, L2Preset preset) {
  final dir = p.join(outDir, 'open-fold');
  var unlockAfter;
  var hadEmpty = false;
  for (final pos in preset.positions) {
    final id = 'l2-open-fold-${pos.toLowerCase()}';
    final path = p.join(dir, '$id.yaml');
    final spots = _writePack(
      path: path,
      id: id,
      name: 'L2 Open/Fold $pos',
      subtype: 'open-fold',
      position: pos,
      tags: ['l2', 'open-fold', pos.toLowerCase(), 'pushfold'],
      unlockAfter: unlockAfter,
    );
    if (spots == 0) hadEmpty = true;
    unlockAfter = id;
  }
  return hadEmpty;
}

bool generate3betPush(Random rng, String outDir, L2Preset preset) {
  final dir = p.join(outDir, '3bet-push');
  var unlockAfter;
  var hadEmpty = false;
  for (final bucket in preset.stackBuckets) {
    final id = 'l2-3bet-push-${bucket}bb';
    final path = p.join(dir, '$id.yaml');
    final spots = _writePack(
      path: path,
      id: id,
      name:
          'L2 3bet Push $bucket'
          'bb',
      subtype: '3bet-push',
      stackBucket: bucket,
      tags: ['l2', '3bet-push', '${bucket}bb', 'vs-open', 'pushfold'],
      unlockAfter: unlockAfter,
    );
    if (spots == 0) hadEmpty = true;
    unlockAfter = id;
  }
  return hadEmpty;
}

bool generateLimped(Random rng, String outDir, L2Preset preset) {
  final dir = p.join(outDir, 'limped');
  var unlockAfter;
  var hadEmpty = false;
  for (final entry in [
    {'pos': 'SB', 'idx': 1},
    {'pos': 'SB', 'idx': 2},
    {'pos': 'SB', 'idx': 3},
    {'pos': 'BB', 'idx': 1},
    {'pos': 'BB', 'idx': 2},
    {'pos': 'BB', 'idx': 3},
  ]) {
    final pos = entry['pos'] as String;
    if (!preset.positions.contains(pos)) {
      continue;
    }
    final idx = entry['idx'] as int;
    final id = 'l2-limped-${pos.toLowerCase()}-$idx';
    final path = p.join(dir, '$id.yaml');
    final spots = _writePack(
      path: path,
      id: id,
      name: 'L2 Limped $pos Pack $idx',
      subtype: 'limped',
      position: pos,
      limped: true,
      tags: ['l2', 'limped', pos.toLowerCase()],
      unlockAfter: unlockAfter,
    );
    if (spots == 0) hadEmpty = true;
    unlockAfter = id;
  }
  return hadEmpty;
}
