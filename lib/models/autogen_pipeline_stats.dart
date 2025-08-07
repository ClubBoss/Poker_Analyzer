class AutogenPipelineStats {
  final int generated;
  final int deduplicated;
  final int curated;
  final int published;

  const AutogenPipelineStats({
    this.generated = 0,
    this.deduplicated = 0,
    this.curated = 0,
    this.published = 0,
  });

  AutogenPipelineStats copyWith({
    int? generated,
    int? deduplicated,
    int? curated,
    int? published,
  }) {
    return AutogenPipelineStats(
      generated: generated ?? this.generated,
      deduplicated: deduplicated ?? this.deduplicated,
      curated: curated ?? this.curated,
      published: published ?? this.published,
    );
  }
}
