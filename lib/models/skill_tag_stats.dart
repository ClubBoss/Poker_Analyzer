class SkillTagStats {
  final Map<String, int> tagCounts;
  final int totalTags;
  final List<String> unusedTags;
  final List<String> overloadedTags;
  final Map<String, List<String>> spotTags;
  final Map<String, int> categoryCounts;
  final Map<String, double> categoryCoverage;

  const SkillTagStats({
    required this.tagCounts,
    required this.totalTags,
    required this.unusedTags,
    required this.overloadedTags,
    this.spotTags = const {},
    this.categoryCounts = const {},
    this.categoryCoverage = const {},
  });
}
