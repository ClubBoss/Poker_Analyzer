class StreakRecoverySuggestion {
  final String title;
  final String packId;
  final String? tagFocus;
  final String ctaText;

  const StreakRecoverySuggestion({
    required this.title,
    required this.packId,
    this.tagFocus,
    required this.ctaText,
  });
}
