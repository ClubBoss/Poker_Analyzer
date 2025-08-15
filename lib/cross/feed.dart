import 'dart:convert';

class FeedItem {
  final String kind;
  final String file;
  final int count;
  final String version;

  const FeedItem({
    required this.kind,
    required this.file,
    required this.count,
    this.version = 'v1',
  });

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'file': file,
    'count': count,
    'version': version,
  };
}

class TrainingFeed {
  final String version;
  final List<FeedItem> items;

  const TrainingFeed({this.version = 'v1', required this.items});

  Map<String, dynamic> toJson() => {
    'version': version,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

String encodeFeedCompact(TrainingFeed f) => jsonEncode(f.toJson());

String encodeFeedPretty(TrainingFeed f) =>
    const JsonEncoder.withIndent('  ').convert(f.toJson());
