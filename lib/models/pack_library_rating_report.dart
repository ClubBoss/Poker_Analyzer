class PackLibraryRatingReport {
  final List<(String, int)> topRatedPacks;
  final Map<String, double> averageScoresByAudience;
  final Map<String, (double, int)> tagInsights;
  const PackLibraryRatingReport({
    this.topRatedPacks = const [],
    this.averageScoresByAudience = const {},
    this.tagInsights = const {},
  });
  Map<String, dynamic> toJson() => {
        'topRatedPacks': [
          for (final e in topRatedPacks) [e.$1, e.$2],
        ],
        'averageScoresByAudience': averageScoresByAudience,
        'tagInsights': {
          for (final e in tagInsights.entries)
            e.key: {'averageScore': e.value.$1, 'count': e.value.$2},
        },
      };
  factory PackLibraryRatingReport.fromJson(Map<String, dynamic> j) {
    final top = <(String, int)>[];
    for (final e in j['topRatedPacks'] as List? ?? []) {
      if (e is List && e.length >= 2) {
        top.add((e[0].toString(), (e[1] as num?)?.toInt() ?? 0));
      }
    }
    final aud = <String, double>{};
    for (final e in (j['averageScoresByAudience'] as Map?)?.entries ?? {}) {
      aud[e.key.toString()] = (e.value as num?)?.toDouble() ?? 0;
    }
    final tags = <String, (double, int)>{};
    for (final e in (j['tagInsights'] as Map?)?.entries ?? {}) {
      final v = e.value;
      if (v is Map) {
        tags[e.key.toString()] = (
          (v['averageScore'] as num?)?.toDouble() ?? 0,
          (v['count'] as num?)?.toInt() ?? 0,
        );
      }
    }
    return PackLibraryRatingReport(
      topRatedPacks: top,
      averageScoresByAudience: aud,
      tagInsights: tags,
    );
  }
}
