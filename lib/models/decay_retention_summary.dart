class DecayRetentionSummary {
  final int totalTags;
  final int decayedTags;
  final double averageDecay;
  final List<String> topForgotten;

  const DecayRetentionSummary({
    required this.totalTags,
    required this.decayedTags,
    required this.averageDecay,
    required this.topForgotten,
  });
}
