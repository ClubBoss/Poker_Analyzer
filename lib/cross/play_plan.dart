import 'dart:convert';
import 'dart:typed_data';

import 'feed_fs.dart';
import 'hash32.dart';

class PlayPlanItem {
  final String id;
  final String kind;
  final String file;
  final int start;
  final int count;

  const PlayPlanItem({
    required this.id,
    required this.kind,
    required this.file,
    required this.start,
    required this.count,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'file': file,
        'start': start,
        'count': count,
      };
}

class PlayPlan {
  final String version;
  final List<PlayPlanItem> items;

  const PlayPlan({this.version = 'v1', required this.items});

  Map<String, dynamic> toJson() => {
        'version': version,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

String encodePlayPlanCompact(PlayPlan p) => jsonEncode(p.toJson());

String encodePlayPlanPretty(PlayPlan p) =>
    const JsonEncoder.withIndent('  ').convert(p.toJson());

PlayPlan buildPlayPlan(
  List<FeedRef> refs, {
  int target = 20,
  int maxSlices = 0,
}) {
  final items = <PlayPlanItem>[];
  var produced = 0;

  for (final ref in refs) {
    var remaining = ref.count;
    var start = 0;
    while (remaining > 0) {
      final take = remaining < target ? remaining : target;
      final input = '${ref.kind}|${ref.path}|$start|$take';
      final id = fnv32Hex(Uint8List.fromList(utf8.encode(input)));
      items.add(
        PlayPlanItem(
          id: id,
          kind: ref.kind,
          file: ref.path,
          start: start,
          count: take,
        ),
      );
      produced++;
      if (maxSlices > 0 && produced >= maxSlices) {
        return PlayPlan(items: items);
      }
      start += take;
      remaining -= take;
    }
  }

  return PlayPlan(items: items);
}
