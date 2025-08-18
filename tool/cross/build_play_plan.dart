import 'dart:io';
import '../../lib/cross/feed_fs.dart';
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

  final refs = readFeedRefs(feedFile);
  if (refs.isEmpty) {
    stderr.writeln('invalid or empty feed: $feedPath');
    exit(2);
  }
  final plan = buildPlayPlan(refs, target: target, maxSlices: maxSlices);
  var l2Count = 0;
  var l3Count = 0;
  var l4Count = 0;
  for (final item in plan.items) {
    if (item.kind == 'l2_session') {
      l2Count++;
    } else if (item.kind == 'l3_session') {
      l3Count++;
    } else if (item.kind == 'l4_session') {
      l4Count++;
    }
  }

  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final outPath = outDir.endsWith('/') ? '$outDir$name' : '$outDir/$name';
  final json = format == 'pretty'
      ? encodePlayPlanPretty(plan)
      : encodePlayPlanCompact(plan);
  File(outPath).writeAsStringSync(json);

  stdout.writeln(
    'wrote plan name=$name slices=${plan.items.length} '
    'target=$target from feed=$feedPath '
    'kinds=l2:$l2Count l3:$l3Count l4:$l4Count',
  );
}

void _usage() {
  stdout.writeln(
    'usage: --feed=FILE [--target N] [--max-slices K] [--format compact|pretty] [--out DIR] [--name FILE]',
  );
  exit(2);
}
