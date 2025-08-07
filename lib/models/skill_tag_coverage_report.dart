class SkillTagCoverageReport {
  final Map<String, int> tagCounts;
  final List<String> underrepresentedTags;

  const SkillTagCoverageReport({
    required this.tagCounts,
    required this.underrepresentedTags,
  });
}
