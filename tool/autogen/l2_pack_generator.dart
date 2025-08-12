import 'dart:io';
import 'dart:math';

void main(List<String> args) {
  final rng = Random(42);
  generateOpenFold(rng);
  generate3betPush(rng);
  generateLimped(rng);
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

void _writePack({
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
  for (var i = 0; i < 80; i++) {
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
}

void generateOpenFold(Random rng) {
  final dir = 'assets/packs/l2/open-fold';
  var unlockAfter;
  for (final pos in ['EP', 'MP', 'CO', 'BTN', 'SB', 'BB']) {
    final id = 'l2-open-fold-${pos.toLowerCase()}';
    final path = '$dir/$id.yaml';
    _writePack(
      path: path,
      id: id,
      name: 'L2 Open/Fold $pos',
      subtype: 'open-fold',
      position: pos,
      tags: ['l2', 'open-fold', pos.toLowerCase(), 'pushfold'],
      unlockAfter: unlockAfter,
    );
    unlockAfter = id;
  }
}

void generate3betPush(Random rng) {
  final dir = 'assets/packs/l2/3bet-push';
  var unlockAfter;
  for (final bucket in ['8-12', '13-18', '19-25', '26-32', '33-40', '41-50']) {
    final id = 'l2-3bet-push-${bucket}bb';
    final path = '$dir/$id.yaml';
    _writePack(
      path: path,
      id: id,
      name: 'L2 3bet Push $bucket' 'bb',
      subtype: '3bet-push',
      stackBucket: bucket,
      tags: ['l2', '3bet-push', '${bucket}bb', 'vs-open', 'pushfold'],
      unlockAfter: unlockAfter,
    );
    unlockAfter = id;
  }
}

void generateLimped(Random rng) {
  final dir = 'assets/packs/l2/limped';
  var unlockAfter;
  for (final entry in [
    {'pos': 'SB', 'idx': 1},
    {'pos': 'SB', 'idx': 2},
    {'pos': 'SB', 'idx': 3},
    {'pos': 'BB', 'idx': 1},
    {'pos': 'BB', 'idx': 2},
    {'pos': 'BB', 'idx': 3},
  ]) {
    final pos = entry['pos'] as String;
    final idx = entry['idx'] as int;
    final id = 'l2-limped-${pos.toLowerCase()}-$idx';
    final path = '$dir/$id.yaml';
    _writePack(
      path: path,
      id: id,
      name: 'L2 Limped $pos Pack $idx',
      subtype: 'limped',
      position: pos,
      limped: true,
      tags: ['l2', 'limped', pos.toLowerCase()],
      unlockAfter: unlockAfter,
    );
    unlockAfter = id;
  }
}
