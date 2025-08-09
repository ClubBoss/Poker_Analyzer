class CoverageReport {
  final int totalTags;
  final int uniqueTags;
  final List<String> topTags;
  final double coveragePct;
  final bool passes;

  const CoverageReport({
    required this.totalTags,
    required this.uniqueTags,
    required this.topTags,
    required this.coveragePct,
    required this.passes,
  });
}
