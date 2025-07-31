class TagDecaySummary {
  final double avgDecay;
  final int countCritical;
  final int countWarning;
  final List<String> mostDecayedTags;

  const TagDecaySummary({
    required this.avgDecay,
    required this.countCritical,
    required this.countWarning,
    required this.mostDecayedTags,
  });
}
