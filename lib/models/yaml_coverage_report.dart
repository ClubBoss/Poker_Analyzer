class YamlCoverageReport {
  final Map<String, int> tags;
  final Map<String, int> categories;
  final Map<String, int> audiences;
  final Map<String, int> positions;
  const YamlCoverageReport({
    required this.tags,
    required this.categories,
    required this.audiences,
    required this.positions,
  });
  Map<String, dynamic> toJson() => {
    'tags': tags,
    'categories': categories,
    'audiences': audiences,
    'positions': positions,
  };
  factory YamlCoverageReport.fromJson(Map<String, dynamic> j) =>
      YamlCoverageReport(
        tags: {
          for (final e in (j['tags'] as Map?)?.entries ?? {})
            e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        },
        categories: {
          for (final e in (j['categories'] as Map?)?.entries ?? {})
            e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        },
        audiences: {
          for (final e in (j['audiences'] as Map?)?.entries ?? {})
            e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        },
        positions: {
          for (final e in (j['positions'] as Map?)?.entries ?? {})
            e.key.toString(): (e.value as num?)?.toInt() ?? 0,
        },
      );
}
