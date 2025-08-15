import 'dart:convert';

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
