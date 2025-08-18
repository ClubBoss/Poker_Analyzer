import 'dart:convert';
import 'dart:io';

import '../../lib/cross/feed.dart';

void main(List<String> args) {
  String? l2Arg;
  String? l3Arg;
  String? l4Arg;
  var format = 'compact';
  var outDir = 'out/feed';
  var name = 'feed_v1.json';

  for (final arg in args) {
    if (arg.startsWith('--l2=')) {
      l2Arg = arg.substring(5);
    } else if (arg.startsWith('--l3=')) {
      l3Arg = arg.substring(5);
    } else if (arg.startsWith('--l4=')) {
      l4Arg = arg.substring(5);
    } else if (arg.startsWith('--format=')) {
      final v = arg.substring(9);
      if (v == 'compact' || v == 'pretty') {
        format = v;
      } else {
        _usage();
      }
    } else if (arg.startsWith('--out=')) {
      outDir = arg.substring(6);
    } else if (arg.startsWith('--name=')) {
      name = arg.substring(7);
    }
  }

  final l2Files = l2Arg == null || l2Arg.isEmpty
      ? <String>[]
      : l2Arg.split(',').where((e) => e.isNotEmpty).toList();
  final l3Files = l3Arg == null || l3Arg.isEmpty
      ? <String>[]
      : l3Arg.split(',').where((e) => e.isNotEmpty).toList();
  final l4Files = l4Arg == null || l4Arg.isEmpty
      ? <String>[]
      : l4Arg.split(',').where((e) => e.isNotEmpty).toList();

  if (l2Files.isEmpty && l3Files.isEmpty && l4Files.isEmpty) {
    _usage();
  }

  final items = <FeedItem>[];
  var l2Count = 0;
  var l3Count = 0;
  var l4Count = 0;

  for (final path in l2Files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('missing file: $path');
      exit(2);
    }
    final data = jsonDecode(file.readAsStringSync());
    final count = (data['items'] is List) ? (data['items'] as List).length : 0;
    items.add(
      FeedItem(kind: 'l2_session', file: path, count: count, version: 'v1'),
    );
    l2Count++;
  }

  for (final path in l3Files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('missing file: $path');
      exit(2);
    }
    final data = jsonDecode(file.readAsStringSync());
    var count = 0;
    if (data['inlineItems'] is List) {
      count = (data['inlineItems'] as List).length;
    } else if (data['items'] is List) {
      count = (data['items'] as List).length;
    }
    items.add(
      FeedItem(kind: 'l3_session', file: path, count: count, version: 'v1'),
    );
    l3Count++;
  }

  for (final path in l4Files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('missing file: $path');
      exit(2);
    }
    final data = jsonDecode(file.readAsStringSync());
    final count = (data['items'] is List) ? (data['items'] as List).length : 0;
    items.add(
      FeedItem(kind: 'l4_session', file: path, count: count, version: 'v1'),
    );
    l4Count++;
  }

  items.sort((a, b) => a.file.compareTo(b.file));
  final feed = TrainingFeed(version: 'v1', items: items);

  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final outPath = outDir.endsWith('/') ? '$outDir$name' : '$outDir/$name';
  final json = format == 'pretty'
      ? encodeFeedPretty(feed)
      : encodeFeedCompact(feed);
  File(outPath).writeAsStringSync(json);

  final total = items.length;
  stdout.writeln(
    'wrote feed name=$name items=$total l2=$l2Count l3=$l3Count l4=$l4Count format=$format',
  );
}

void _usage() {
  stdout.writeln(
    'usage: --l2 a.json,b.json [--l3 c.json,d.json] [--l4 e.json,f.json] [--format compact|pretty] [--out dir] [--name file]',
  );
  exit(2);
}
