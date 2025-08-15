import 'dart:convert';
import 'dart:io';

import '../../lib/cross/play_plan.dart';

void main(List<String> args) {
  String? feedPath;
  var target = 20;
  var maxSlices = 0;
  var format = 'compact';
  var outDir = 'out/plan';
  var name = 'play_plan_v1.json';

  for (final arg in args) {
    if (arg.startsWith('--feed=')) {
      feedPath = arg.substring(7);
    } else if (arg.startsWith('--target=')) {
      final v = int.tryParse(arg.substring(9));
      if (v == null || v <= 0) {
        _usage();
      }
      target = v;
    } else if (arg.startsWith('--max-slices=')) {
      final v = int.tryParse(arg.substring(13));
      if (v == null || v < 0) {
        _usage();
      }
      maxSlices = v;
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
    } else {
      _usage();
    }
  }

  if (feedPath == null) {
    _usage();
  }

  final feedFile = File(feedPath!);
  if (!feedFile.existsSync()) {
    stderr.writeln('missing feed: $feedPath');
    exit(2);
  }

  final feedData = jsonDecode(feedFile.readAsStringSync());
  if (feedData is! Map || feedData['items'] is! List) {
    stderr.writeln('invalid feed: $feedPath');
    exit(2);
  }
  final itemsData = feedData['items'] as List;

  final planItems = <PlayPlanItem>[];
  var l2Count = 0;
  var l3Count = 0;
  var l4Count = 0;

  outer:
  for (final item in itemsData) {
    if (item is! Map) {
      continue;
    }
    final kind = item['kind'] as String? ?? '';
    final file = item['file'] as String? ?? '';
    final total = item['count'] is int
        ? item['count'] as int
        : int.tryParse('${item['count']}') ?? 0;
    var start = 0;
    var remaining = total;
    while (remaining > 0) {
      final take = remaining < target ? remaining : target;
      final idInput = '$kind|$file|$start|$take';
      final id = _h32(idInput);
      planItems.add(
        PlayPlanItem(
          id: id,
          kind: kind,
          file: file,
          start: start,
          count: take,
        ),
      );
      if (kind == 'l2_session') {
        l2Count++;
      } else if (kind == 'l3_session') {
        l3Count++;
      } else if (kind == 'l4_session') {
        l4Count++;
      }
      if (maxSlices > 0 && planItems.length >= maxSlices) {
        break outer;
      }
      start += take;
      remaining -= take;
    }
  }

  final plan = PlayPlan(items: planItems);

  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final outPath = outDir.endsWith('/') ? '$outDir$name' : '$outDir/$name';
  final json =
      format == 'pretty' ? encodePlayPlanPretty(plan) : encodePlayPlanCompact(plan);
  File(outPath).writeAsStringSync(json);

  stdout.writeln(
      'wrote plan name=$name slices=${planItems.length} target=$target from feed=$feedPath kinds=l2:$l2Count l3:$l3Count l4:$l4Count');
}

String _h32(String s) {
  const int prime = 0x01000193;
  var hash = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    hash ^= s.codeUnitAt(i);
    hash = (hash * prime) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

void _usage() {
  stdout.writeln(
      'usage: --feed=FILE [--target N] [--max-slices K] [--format compact|pretty] [--out DIR] [--name FILE]');
  exit(2);
}
